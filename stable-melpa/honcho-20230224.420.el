;;; honcho.el --- Run and manage long-running services            -*- lexical-binding: t -*-

;; Copyright (c) 2016 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/honcho.el
;; Package-Version: 20230224.420
;; Package-Commit: 95846309c6a4ce45f29f215d43847beb510b6aca
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Manage external services from within Emacs.
;;
;; Defining services:
;;
;; A minimal example to define a service with `honcho-define-service`
;;
;;     (honcho-define-service python-server
;;       :command ("python" "-m" "http.server"))
;;
;; To list the services, use `M-x honcho'.  There is also `M-x honcho-procfile' to
;; load services from a Procfile.
;;
;;     (honcho-define-service node-server
;;       :command ("node" "server.js")
;;       :cwd     "/path/to/project/"
;;       :env     (("NODE_ENV"  . "development")
;;                 ("REDIS_URL" . "redis://localhost:6379/0")))
;;
;; Troubleshooting:
;;
;; + **The service buffer contains ANSI control sequences**
;;
;;   `honcho' uses `compilation-mode' underneath, it's recommended to setup
;;   [xterm-color][] for `compilation-mode'.
;;
;; Related projects:
;;
;; + [prodigy.el][]: Manage external services from within Emacs
;;
;; [prodigy.el]: https://github.com/rejeep/prodigy.el
;; [xterm-color]: https://github.com/atomontage/xterm-color

;;; Code:
(eval-when-compile
  (require 'cl-lib)
  (require 'subr-x))
(require 'compile)

(declare-function sudo-edit-filename "sudo-edit")

(defgroup honcho nil
  "Manage external services from within Emacs."
  :prefix "honcho-"
  :group 'applications)

(defcustom honcho-sudo-user "root"
  "User as which to start a service with the sudo option."
  :type 'string
  :group 'honcho)

(defcustom honcho-working-directory "~"
  "Default working directory for honcho services."
  :type '(directory :must-match t)
  :group 'honcho)

(defcustom honcho-procfile-env-suffix-p t
  "Whether to load the dotenv according the procfile extension.

For instance a `honcho-procfile' set to \"Procfile.dev\" will
load `.env.dev' i.e. will use the same suffix."
  :type 'boolean
  :group 'honcho)

(defcustom honcho-signal-list
  '(("HUP" . "   (1.  Hangup)")
    ("INT" . "   (2.  Terminal interrupt)")
    ("QUIT" . "  (3.  Terminal quit)")
    ("ABRT" . "  (6.  Process abort)")
    ("KILL" . "  (9.  Kill - cannot be caught or ignored)")
    ("ALRM" . "  (14. Alarm Clock)")
    ("TERM" . "  (15. Termination)")
    ("CONT" . "  (Continue executing)")
    ("STOP" . "  (Stop executing / pause - cannot be caught or ignored)")
    ("TSTP" . "  (Terminal stop / pause)"))
  "List of signals, used for minibuffer completion."
  :type '(repeat (cons (string :tag "signal name")
                       (string :tag "description")))
  :group 'honcho)

(defface honcho-loaded
  '((t (:inherit shadow)))
  "Face for showing process loaded."
  :group 'honcho)

(defface honcho-success
  '((t (:inherit success)))
  "Face for showing process started."
  :group 'honcho)

(defface honcho-failed
  '((t (:inherit error)))
  "Face for showing process failed."
  :group 'honcho)

(defface honcho-stopped
  '((t (:inherit warning)))
  "Face for showing process successfully stopped."
  :group 'honcho)

(defvar honcho-services (make-hash-table :test #'equal)
  "Table holding the information for honcho services.")
(defvar honcho-buffer-name "*honcho*"
  "Name of the buffer used for listing the services.")
(defvar honcho-services-switch #'switch-to-buffer
  "Function to call to display and switch to the honcho process list.")
(defvar honcho-dotenv ".env"
  "Dotenv filename.")
;;;###autoload
(defvar honcho-procfile "Procfile"
  "File name of the default Procfile.")
;;;###autoload
(put 'honcho-procfile 'safe-local-variable #'stringp)

;; See: https://github.com/ddollar/foreman/blob/025de2a/lib/foreman/procfile.rb#L5-L9
(defconst honcho-procfile-command-regexp
  (rx line-start
      (group (+ (in alnum ?_)))         ; name
      ?:                                ; separator
      (* space) (group (+ any))         ; command
      line-end)
  "Regexp of a Procfile command definition.")

(defmacro honcho-with-directory (directory &rest body)
  "Bind DIRECTORY as `default-directory' and execute BODY."
  (declare (indent 1) (debug t))
  `(let ((default-directory (or (and ,directory (file-name-as-directory ,directory))
                                default-directory)))
     ,@body))

(defmacro honcho-with-environ (env &rest body)
  "Add ENV to `process-environment' in BODY.

ENV is an alist, where each cons cell `(VAR . VALUE)' is a
environment variable VAR to be added to `process-environment'
with VALUE."
  (declare (indent 1))
  `(let ((process-environment (copy-sequence process-environment)))
     (pcase-dolist (`(,var . ,value) ,env)
       (setenv var value))
     ,@body))

(cl-defstruct (honcho-service (:copier nil)
                              (:constructor honcho-service-new))
  "A structure holding all the information of a honcho service."
  name                                  ; process name
  command                               ; command
  env                                   ; environment variables
  sudo                                  ; whether to start project with sudo
  process                               ; process reference
  (cwd honcho-working-directory))       ; working directory

(defun honcho-file-lines (file)
  "Return a list of strings containing one element per line in FILE."
  (let* ((visiting (find-buffer-visiting file))
         (buffer (or visiting (find-file-noselect file 'nowarn 'rawfile))))
    (unwind-protect
        (with-current-buffer buffer
          (split-string (buffer-substring-no-properties (point-min) (point-max)) "\n" 'omit-nulls))
      (unless visiting (kill-buffer buffer)))))

(defun honcho-menu-visit-buffer (button)
  "Display process buffer associated to BUTTON."
  (display-buffer (button-get button 'process-buffer)))

(defun honcho-dotenv-ext (procfile)
  "Guess dotenv suffix from a PROCFILE name."
  (and honcho-procfile-env-suffix-p (let ((ext (file-name-extension procfile))) (and ext (concat "." ext)))))

(defun honcho-collect-dotenv (dotenv &optional extension)
  "Return a list of environment variables in DOTENV file with EXTENSION."
  (cl-loop for line in (honcho-file-lines (concat dotenv extension))
           when (string-match "^\\(.+[^[:space:]]\\)[[:space:]]*=[[:space:]]*\\(.+\\)" line)
           collect (cons (match-string-no-properties 1 line) (match-string-no-properties 2 line))))

(defun honcho-collect-commands (procfile)
  "Return a list of commands defined in PROCFILE."
  (cl-loop for line in (honcho-file-lines procfile)
           when (string-match honcho-procfile-command-regexp line)
           collect (list (match-string 1 line) (split-string-and-unquote (match-string 2 line)))))

(defun honcho-collect-procfile-services (procfile)
  "Collect the services defined in PROCFILE."
  (setq honcho-services
        (cl-loop with cwd = (file-name-directory procfile)
                 with env = (honcho-collect-dotenv honcho-dotenv (honcho-dotenv-ext procfile))
                 with services = honcho-services
                 for (name command) in (honcho-collect-commands procfile)
                 if (gethash name services)
                 do (setf (honcho-service-env it) env (honcho-service-command it) command)
                 else do (puthash name (honcho-service-new :name name :command command :env env :cwd cwd) services)
                 finally return services)))

(defun honcho-process-status (process)
  "Return an string to show the current PROCESS status."
  (cond
   ((null process)
    (propertize "loaded" 'face 'honcho-loaded))
   ((process-live-p process)
    (propertize "started" 'face 'honcho-success))
   ((zerop (process-exit-status process))
    (propertize "stopped" 'face 'honcho-stopped 'help-echo "status: 0/SUCCESS"))
   (t (propertize "failed" 'face 'honcho-failed 'help-echo (format "status: %s/FAILURE" (process-exit-status process))))))

(defun honcho-entry-generate (service)
  "Generate a tabulated list entry from a honcho SERVICE."
  (list (honcho-service-name service)
        (vector (honcho-process-status (honcho-service-process service))
                (if-let ((process (honcho-service-process service))
                         (buffer (process-buffer process)))
                    `(,(honcho-service-name service)
                      face link
                      help-echo ,(format-message "Visit buffer for service `%s'" (honcho-service-name service))
                      follow-link t
                      process-buffer ,buffer
                      action honcho-menu-visit-buffer)
                  (honcho-service-name service))
                (string-join (honcho-service-command service) " "))))

(defun honcho-read-service-name (prompt)
  "Read service from `honcho-services' with PROMPT."
  (let ((default (and (derived-mode-p 'honcho-menu-mode) (tabulated-list-get-id))))
    (or (and (not current-prefix-arg) default)
        (completing-read prompt (hash-table-keys honcho-services) nil t nil nil default))))

(defun honcho-read-signal (prompt)
  "Read Unix signal with PROMPT."
  (let ((completion-ignore-case t)
        (completion-extra-properties '(:annotation-function (lambda (s) (assoc-default s honcho-signal-list)))))
    (completing-read prompt honcho-signal-list)))

(defun honcho-enable-comint ()
  "Enable `comint-mode' for the current `compile' buffer."
  (interactive)
  (unless (derived-mode-p 'compilation-mode)
    (user-error "Cannot enable comint a non-compilation buffer"))
  (setq buffer-read-only nil)
  (with-no-warnings (comint-mode))
  (compilation-shell-minor-mode))

(defun honcho-maybe-revert-menu ()
  "Revert refresh services menu buffer."
  (when (derived-mode-p 'honcho-menu-mode)
    (sleep-for 0.1)
    (tabulated-list-print 'remember-pos)))

(defun honcho-entries-services ()
  "Return a list of `tabulated-list-entries' of the honcho services."
  (mapcar #'honcho-entry-generate (hash-table-values honcho-services)))

(defun honcho-procfile-entries-services (procfile)
  "Return a list of `tabulated-list-entries' from a PROCFILE."
  (mapcar #'honcho-entry-generate (hash-table-values (honcho-collect-procfile-services procfile))))

(define-derived-mode honcho-menu-mode tabulated-list-mode "Honcho"
  "Special mode for honcho buffers."
  (setq tabulated-list-format [("status"   8 t)
                               ("name"    15 t)
                               ("command" 20 t)]
        tabulated-list-padding 2
        tabulated-list-entries #'honcho-entries-services)
  (tabulated-list-init-header))

(define-key honcho-menu-mode-map "s" #'honcho-start-service)
(define-key honcho-menu-mode-map "S" #'honcho-stop-service)
(define-key honcho-menu-mode-map "k" #'honcho-signal-service)

(define-compilation-mode honcho-view-mode "Honcho-View"
  "Mode for viewing honcho process output.")

(define-key honcho-view-mode-map "c" #'honcho-enable-comint)

;;;###autoload
(defmacro honcho-define-service (symbol &rest properties)
  "Register a honcho service with SYMBOL and PROPERTIES.

`:command COMMAND'
    A list containing the command which will be used for the service.

`:cwd DIRECTORY'
    Directory from which the service will start.

`:sudo SUDO'
    Whether to start the service with sudo.  When set to a string, will be the
    user used to start a service.

`:env ENVIRON'
   An alist where each cons cell `(VAR . VALUE)' with the environment variables
   which will be used to start a service."
  (declare (indent defun) (doc-string 2))
  (let ((name (if (stringp symbol) symbol (symbol-name symbol)))
        (sudo (plist-get properties :sudo))
        (cmd  (plist-get properties :command))
        (env  (plist-get properties :env))
        (cwd  (or (plist-get properties :cwd) honcho-working-directory)))

    (when (null cmd)
      (user-error ":command property is required"))

    (unless (listp cmd)
      (user-error ":command property should be a list"))

    `(puthash ,name
              (honcho-service-new :name    ,name
                                  :sudo    ,sudo
                                  :cwd     ,cwd
                                  :env     ',env
                                  :command ',cmd)
              honcho-services)))

;;;###autoload
(defun honcho-start-service (name)
  "Start service identified by NAME."
  (interactive (list (honcho-read-service-name "Service: ")))
  (let ((service (gethash name honcho-services)))
    (cl-assert (cl-typep service 'honcho-service) nil "Could not find service with name: %s" name)
    (honcho-with-directory (if (honcho-service-sudo service)
                               (if (fboundp 'sudo-edit-filename)
                                   (sudo-edit-filename (honcho-service-cwd service) (if (stringp (honcho-service-sudo service)) (honcho-service-sudo service) honcho-sudo-user))
                                 (user-error "Support for sudo services requires the package `sudo-edit'"))
                             (honcho-service-cwd service))
      (honcho-with-environ (honcho-service-env service)
        (save-some-buffers (not compilation-ask-about-save) nil)
        (setf (honcho-service-process service)
              (get-buffer-process (compilation-start (mapconcat #'shell-quote-argument (honcho-service-command service) " ")
                                                     #'honcho-view-mode
                                                     (lambda (_mode)
                                                       (format "*honcho-service[%s]*" name)))))))
    (honcho-maybe-revert-menu)))

;;;###autoload
(defun honcho-stop-service (name)
  "Stop service identified by NAME."
  (interactive (list (honcho-read-service-name "Service: ")))
  (let ((service (gethash name honcho-services)))
    (cl-assert (cl-typep service 'honcho-service) nil "Could not find service with name: %s" name)
    (delete-process (honcho-service-process service))
    (honcho-maybe-revert-menu)))

;;;###autoload
(defun honcho-signal-service (name)
  "Send signal to service identified by NAME."
  (interactive (list (honcho-read-service-name "Service: ")))
  (let ((service (gethash name honcho-services)))
    (cl-assert (cl-typep service 'honcho-service) nil "Could not find service with name: %s" name)
    (with-demoted-errors "Error sending signal: %S"
      (signal-process (honcho-service-process service) (intern (honcho-read-signal "Signal: "))))
    (honcho-maybe-revert-menu)))

;;;###autoload
(defun honcho ()
  "Run and manage long-running services."
  (interactive)
  (with-current-buffer (get-buffer-create honcho-buffer-name)
    (honcho-menu-mode)
    (tabulated-list-print)
    (funcall honcho-services-switch (current-buffer))))

;;;###autoload
(defun honcho-procfile (procfile)
  "Manage external services from a PROCFILE."
  (interactive (let* ((root-dir (locate-dominating-file default-directory honcho-procfile))
                      (procfile (and root-dir (expand-file-name honcho-procfile root-dir))))
                 (list (or (and (not current-prefix-arg) procfile)
                           (read-file-name "Procfile: " nil procfile t)))))
  (honcho-with-directory (file-name-directory procfile)
    (with-current-buffer (get-buffer-create (format "*Honcho[%s]*" (abbreviate-file-name procfile)))
      (let* ((local-p (local-variable-if-set-p 'honcho-services))
             (services (and local-p honcho-services)))
        (honcho-menu-mode)
        (setq-local honcho-services (if local-p services (make-hash-table :test #'equal)))
        (setq tabulated-list-entries (apply-partially #'honcho-procfile-entries-services procfile))
        (tabulated-list-print)
        (funcall honcho-services-switch (current-buffer))))))

(provide 'honcho)
;;; honcho.el ends here
