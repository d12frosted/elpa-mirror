;;; navorski.el --- Helping you live in the terminal, like Viktor did.

;; Copyright (C) 2013, 2014 Roman Gonzalez.
;; Copyright (C) 2013 Birdseye Software, Inc.

;; Author: Roman Gonzalez <romanandreg@gmail.com>, Tavis Rudd <tavis@birdseye-sw.com>
;; Maintainer: Roman Gonzalez <romanandreg@gmail.com>
;; Version: 0.2.7
;; Package-Version: 20141203.1824
;; Package-Commit: 698c1c62da70164aebe9a7a5d034778fbc30ea5b
;; Package-Requires: ((s "1.9.0") (dash "1.5.0") (multi-term "0.8.14"))
;; Keywords: terminal

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  This program is
;; distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.  You should have received a copy of the
;; GNU General Public License along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Require:

(require 'time-stamp)
(require 'multi-term)
(require 'assoc)
(require 'dash)

;;; Code:

(eval-when-compile
  (require 'tramp)) ; required because `with-parsed-tramp-file-name' is a macro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables

(defcustom navorski-buffer-name "terminal"
  "Default buffer name for terminal."
  :type 'string
  :group 'navorski)

(defcustom navorski-verbose nil
  "Print debug information on message buffer"
  :type 'bool
  :group 'navorski)

(defvar navorski-profile-map (make-hash-table :test 'equal)
  "Collection of navorski profiles")

(defvar navorski-read-only-term-map (suppress-keymap (make-sparse-keymap))
  "Keymap for read-only term")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keybindings for terminal buffers

;; IMPORTANT: all terminal keybindings need to be interactive
;; otherwise they won't work

(defun -navorski-term-reverse-search ()
  (interactive)
  (if (term-in-line-mode)
      (isearch-backward)
    (term-send-reverse-search-history)))

(defun -navorski-term-dabbrev ()
  (interactive)
  (let ((beg (point)))
    (dabbrev-expand nil)
    (kill-region beg (point)))
  (term-send-raw-string (substring-no-properties (current-kill 0))))

(defun -navorski-term-backward-kill-word ()
  (interactive)
  (if (term-in-line-mode)
      (backward-kill-word 1)
    (term-send-backward-kill-word)))

(defun -navorski-insert-path (file)
  "insert file"
  (interactive "FPath: ")
  (insert (replace-regexp-in-string (getenv "HOME") "~" (expand-file-name file))))

(defun -navorski-term-insert-path ()
  (interactive)
  (let ((beg (point)))
    (call-interactively '-navorski-insert-path)
    (kill-region beg (point)))
  (term-send-raw-string (substring-no-properties (current-kill 0))))

(defun -navorski-term-yank ()
  (interactive)
  (if (term-in-line-mode)
      (yank)
    (term-paste)))

(defun -navorski-interrupt-process ()
  ;; NOTE: interactive is needed here, otherwise
  ;; C-c C-c doesn't work correctly
  (interactive)
  (term-send-raw-string (kbd "C-C")))

(setq term-bind-key-alist
      '(("C-c C-c" . -navorski-interrupt-process)
        ("C-x C-x" . term-send-raw)
        ("C-x C-e" . (lambda ()
                       (interactive)
                       (term-send-raw-string "\C-x\C-e")))
        ("C-s" . isearch-forward)
        ("C-r" . -navorski-term-reverse-search)
        ("C-m" . term-send-raw)

        ("M-/" . -navorski-term-dabbrev)
        ("M-RET" . find-file-at-point)
        ("M-DEL" . -navorski-term-backward-kill-word)
        ("M-t" . -navorski-term-insert-path)
        ("M-k" . term-send-raw-meta)
        ("M-y" . term-send-raw-meta)
        ("M-u" . term-send-raw-meta)
        ("C-M-k" . (lambda ()
                     (interactive)
                     (term-send-raw-string "\e\C-k")))
        ("C-M-l" . (lambda ()
                     (interactive)
                     (term-send-raw-string "\e\C-l")))
        ("C-M-d" . (lambda ()
                     (interactive)
                     (term-send-raw-string "\e\C-d")))
        ("C-M-t" . (lambda ()
                     (interactive)
                     (term-send-raw-string "\e\C-t")))
        ("M-h" . term-send-raw-meta)
        ("M-s" . term-send-raw-meta)

        ("M-c" . term-send-raw-meta)
        ("M-l" . term-send-raw-meta)
        ("M-|" . term-send-raw-meta)

        ("M-f" . term-send-forward-word)
        ("M-b" . term-send-backward-word)
        ("M-o" . term-send-backspace)
        ("M-p" . term-send-up)
        ("M-n" . term-send-down)
        ("M-N" . term-send-backward-kill-word)
        ("M-r" . term-send-reverse-search-history)

        ("M-," . term-send-input)

        ("M-." . comint-dynamic-complete)
        ("" . term-send-backward-word)
        ("" . term-send-forward-word)
        ("M-d" . term-send-forward-kill-word)
        ("C-y" . -navorski-term-yank)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utils

(defun -navorski-merge-alist (a1 a2)
  (let ((a1_ (copy-alist a1)))
    (dolist (x a2)
      (let ((r (assoc (car x) a1_)))
        (if (null r)
            (add-to-list 'a1_ x)
          (setf (cdr r) (cdr x)))))
    a1_))

(defun -navorski-profile-setting-to-list (setting)
  (and setting
       (if (listp setting)
           setting
         (list setting))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Profiles Manager functions

(defun -navorski-put-profile (profile-name profile)
  (puthash profile-name profile navorski-profile-map))

(defun -navorski-get-profile (profile-name)
  (gethash profile-name navorski-profile-map))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Profile accessors

;;;;;;;;;; General

(defun -navorski-profile-get (profile key &optional def)
  (let ((result (aget profile key)))
    (if (equal result key)
        nil
      result)))

(defun -navorski-profile-set (profile0 key val)
  (let* ((profile (copy-alist profile0))
         (pair (assoc key profile)))
    (if pair
        (progn
          (setf (cdr pair) val)
          profile)
      (append profile `((,key . ,val))))))

(defun -navorski-profile-modify (profile key f)
  (-navorski-profile-set
   profile
   key
   (funcall f (-navorski-profile-get profile key))))

;;;;;;;;;; Fields

(defun -navorski-get-kill-buffer-on-stop (profile)
  (-navorski-profile-get profile :kill-buffer-on-stop))

(defun -navorski-get-profile-name (profile)
  (-navorski-profile-get profile :profile-name))

(defun -navorski-get-interactive (profile)
  (-navorski-profile-get profile :interactive))

(defun -navorski-get-shell-path (profile)
  (or (-navorski-profile-get profile :program-path)
      multi-term-program
      (getenv "SHELL")
      (getenv "ESHELL")
      "/bin/sh"))

;;; start -navorski-get-buffer-name

(defun -navorski-indexed-buffer-name (buffer-name &optional current-index)
  (if (> current-index 0)
      (format "%s<%s>"
              buffer-name
              current-index)
    (format "%s" buffer-name)))

(defun -navorski-get-unnamed-terminal-count ()
  (length (--filter (string-match "\*terminal" (buffer-name it))
                    (buffer-list))))

(defun -navorski-next-buffer-name (&optional buffer-name)
  (let* ((term-count        (-navorski-get-unnamed-terminal-count))
         (buffer-name       (or buffer-name
                                navorski-buffer-name)))
    (-navorski-indexed-buffer-name buffer-name term-count)))

(defun -navorski-get-buffer-name (profile)
  (let ((buffer-name (format "%s"
                             (or (aget profile :buffer-name)
                                 (aget profile :profile-name)
                                 "terminal"))))
    (if (aget profile :unique)
        buffer-name
      (-navorski-next-buffer-name buffer-name))))

;;; end  -navorski-get-buffer-name

(defun -navorski-get-default-directory (profile)
  (let ((cwd (-navorski-profile-get profile :cwd)))
    (cond ((functionp cwd) (funcall cwd default-directory))
          (cwd cwd)
          (t default-directory))))

(defun -navorski-get-init-script (profile)
  (-navorski-profile-setting-to-list
   (-navorski-profile-get profile :init-script)))

(defun -navorski-get-read-only (profile)
  (-navorski-profile-get profile :read-only))

(defun -navorski-get-program-args (profile)
  (-navorski-profile-setting-to-list
   (-navorski-profile-get profile :program-args)))

(defun -navorski-get-hostname (profile)
  (let ((remote-host (-navorski-profile-get profile :remote-host)))
    (if (s-index-of "@" remote-host)
        (second (s-split "@" remote-host))
      remote-host)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Terminal buffer sentinels and filters

(defun -navorski-decorate-multi-term-sentinel (profile term-buffer)
  (let* ((profile-name (-navorski-get-profile-name profile))
         (kill-buffer-on-stop (-navorski-get-kill-buffer-on-stop profile))
         (term-process (get-buffer-process term-buffer))
         (current-sentinel (process-sentinel term-process)))
    (set-process-sentinel term-process
                          `(lambda (proc change)
                             ;; TODO: work out notifying when process is gone
                             (let* ((inhebit-read-only t))
                               (if (string-match "exited abnormally with code \\([0-9]+\\)" change)
                                   (unless (string-equal (match-string 1 change) "0")
                                     (message "[navorski:%s] INFO - %s" ',profile-name change)
                                     (when ',kill-buffer-on-stop
                                       (funcall ',current-sentinel proc change)))
                                 (when ',kill-buffer-on-stop
                                   (funcall ',current-sentinel proc change))))))))

(defun -navorski-decorate-multi-term-process-filter (profile term-buffer)
  (let* ((profile-name (-navorski-get-profile-name profile))
         (read-only (-navorski-get-read-only profile))
         (term-process (get-buffer-process term-buffer))
         (current-filter (process-filter term-process)))
    (set-process-filter term-process
                        `(lambda (proc str)
                           (with-current-buffer ',term-buffer
                             (setq buffer-read-only nil))
                           (funcall ',current-filter proc str)
                           (with-current-buffer ',term-buffer
                             (setq buffer-read-only ',read-only))))))


(defun -navorski-read-only-term-mode ()
  (multi-term-internal)
  (buffer-disable-undo)
  (use-local-map navorski-read-only-term-map)
  (setq buffer-read-only t))

(defun -navorski-create-term-buffer (profile)
  (with-temp-buffer
    (let* ((default-directory (-navorski-get-default-directory profile))

           (shell-name   (-navorski-get-shell-path profile))
           (buffer-name  (-navorski-get-buffer-name profile))
           (program-args (-navorski-get-program-args profile))
           (read-only (-navorski-get-read-only profile))

           (init-script  (-navorski-get-init-script profile))

           (term-buffer  (or (if program-args
                                 (apply #'make-term
                                        buffer-name shell-name nil program-args)
                               (make-term buffer-name shell-name)))))
      (when navorski-verbose
        (message
         (format "[navorski] EXECUTE: %s %s on DIRECTORY=%s"
                 shell-name
                 (or (and program-args
                          (mapconcat 'identity program-args " "))
                     "")
                 default-directory)))

      (with-current-buffer term-buffer
        (if read-only
            (-navorski-read-only-term-mode)
          (multi-term-internal))
        (-navorski-decorate-multi-term-sentinel profile term-buffer)
        (-navorski-decorate-multi-term-process-filter profile term-buffer)

        (when init-script
          (-map (lambda (s) (term-send-raw-string (concat s "\n")))
                init-script)))

      term-buffer)))

(defun -navorski-get-raw-buffer (profile)
  "Get term buffer."
  (with-temp-buffer
    (let* ((buffer-name  (-navorski-get-buffer-name profile))
           (term-buffer  (or (and (aget profile :unique)
                                  (get-buffer buffer-name))
                             (-navorski-create-term-buffer profile))))
      (switch-to-buffer term-buffer)
      term-buffer)))

(defun -navorski-get-buffer (profile0)
  (let* ((remote-host (-navorski-profile-get profile0 :remote-host))
         (screen-name (-navorski-profile-get profile0 :screen-session-name))
         (profile1 (if screen-name
                       (-navorski-persistent-term-to-local-term profile)
                     profile0))
         (profile (if remote-host
                      (-navorski-remote-term-to-local-term profile1)
                    profile1)))
    (-navorski-get-raw-buffer profile)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tramp configuration code

;; derived from http://www.enigmacurry.com/2008/12/26/emacs-ansi-term-tricks/
;; stolen from http://github.com/tavisrudd/emacs.d
(defun -navorski-remote-term-setup-tramp-string (&optional remote-host)
  "Setup ansi-term/tramp remote directory tracking
   NOTE:  this appears to have some sort of timing bug in it and doesn't always work"
  (concat "
function eterm_set_variables {\n"
"local emacs_host=\"" (car (split-string (system-name) "\\.")) "\"\n"
(if remote-host
  (format  "local tramp_hostname=\"%s\"\n" remote-host)
"local tramp_hostname=${TRAMP_HOSTNAME-$(hostname)}\n")
"if [[ $TERM == \"eterm-color\" || $TERM == \"xterm\" || $TERM  == \"xterm-256color\" ]]; then\n"
"    if [[ $tramp_hostname != \"$emacs_host\" ]]; then\n"
"       echo -e \"\\033AnSiTu\" ${TRAMP_USERNAME-$(whoami)}\n"
"       echo -e \"\\033AnSiTh\" $tramp_hostname\n"
"   fi\n"
"   echo -e \"\\033AnSiTc\" $(pwd)\n"
"elif [[ $TERM == \"screen\" || $TERM  == \"screen-256color\" ]]; then\n"
"   if [[ $tramp_hostname != \"$emacs_host\" ]]; then\n"
"       echo -e \"\\033P\\033AnSiTu\\033\\\\\" ${TRAMP_USERNAME-$(whoami)}\n"
"       echo -e \"\\033P\\033AnSiTh\\033\\\\\" $tramp_hostname\n"
"   fi\n"
"   echo -e \"\\033P\\033AnSiTc\\033\\\\\" $(pwd)\n"
"fi\n"
"}\n"
"function eterm_tramp_init {\n"
"for temp in cd pushd popd; do\n"
"   alias $temp=\"eterm_set_cwd $temp\"\n"
"done\n"
"# set hostname, user, and cwd now\n"
"eterm_set_variables\n"
"}\n"
"function eterm_set_cwd {\n"
"$@\n"
"eterm_set_variables\n"
"}\n"
"eterm_tramp_init\n"
"export -f eterm_tramp_init\n"
"export -f eterm_set_variables\n"
"export -f eterm_set_cwd\n"
"clear\n"
"echo \"tramp initialized\""))

(defun -navorski-remote-term-setup-program-args (profile)
  (let ((remote-host (-navorski-profile-get profile :remote-host))
        (remote-port (-navorski-profile-get profile :remote-port))
        (remote-program-args (-navorski-profile-get profile :program-args))
        (remote-program-path (-navorski-get-shell-path profile)))
    (-navorski-profile-modify
     profile
     :program-args
     (lambda (args)
       (append (list "-t")
               (when remote-port
                 (list "-p" remote-port))
               (list remote-host)
               (list remote-program-path)
               remote-program-args)))))

(defun -navorski-remote-term-setup-tramp (profile)
  (let ((use-tramp (-navorski-profile-get profile :use-tramp)))
    (if use-tramp
        (-navorski-profile-modify
         profile
         :init-script
         (lambda (val)
           (append val
                   (list (-navorski-remote-term-setup-tramp-string
                          (-navorski-get-hostname profile))))))
      profile)))

(defun -navorski-remote-term-setup-remote-host (profile)
  (-navorski-profile-modify
   profile
   :remote-host
   (lambda (remote-host)
     (or remote-host
         (read-from-minibuffer
          "SSH address (e.g user@host): " nil nil nil
          'nav/remote-term)))))

(defun -navorski-remote-term-setup-buffer-name (profile)
  (-navorski-profile-modify
   profile
   :buffer-name
   (lambda (buffer-name)
     (or buffer-name
         "remote-terminal"))))

(defun -navorski-remote-term-to-local-term (profile)
  (-> profile
    (-navorski-remote-term-setup-buffer-name)
    (-navorski-remote-term-setup-remote-host)
    (-navorski-remote-term-setup-program-args)
    (-navorski-profile-set :program-path "ssh")
    (-navorski-remote-term-setup-tramp)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GNU Screen configuration code

(defun -navorski-persistent-term-setup-session-name (profile)
  (-navorski-profile-modify
   profile
   :screen-session-name
   (lambda (session-name)
     (or session-name
         (read-from-minibuffer "GNU Screen session name: "
                               nil nil nil
                               'nav/persistent-term)))))

(defun -navorski-persistent-term-setup-program-args (profile)
  (let ((inner-program-path (-navorski-get-shell-path profile))
        (inner-program-args (-navorski-profile-get profile :program-args))
        (screen-name (-navorski-profile-get profile :screen-session-name))
        (screen-args (-navorski-profile-get profile :screen-args)))
    (when inner-program-args
      (message "[navorski] ERROR: can't have arguments for commands on GNU screen sessions"))
    (-navorski-profile-set
     profile
     :program-args
     (append (list "-x" "-R" "-S" screen-name "-s" inner-program-path)
             screen-args))))

(defun -navorski-persistent-term-to-local-term (profile)
  (-> profile
    (-navorski-persistent-term-setup-session-name)
    (-navorski-persistent-term-setup-program-args)
    (-navorski-profile-set :program-path "screen")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Functions to use with a navorski profile

(defun nav/pop-to-buffer (profile)
  (pop-to-buffer (-navorski-get-buffer profile)))

(defun nav/kill-buffer (profile &optional kill-process)
  (let ((term-buffer (-navorski-get-buffer profile)))
    (when kill-process
      (set-process-query-on-exit-flag (get-buffer-process term-buffer) nil)
      (get-buffer-process term-buffer))
    (kill-buffer term-buffer)))

(defun nav/send-string (profile str)
  (with-current-buffer (-navorski-get-buffer profile)
    (let ((inhibit-read-only t))
      (term-send-raw-string (concat str "\n")))))

(defun nav/send-region (profile start end)
  (nav/send-string profile (buffer-substring start end)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Macros

(defmacro -navorski-def-interactive (profile-name profile)
  (when (-navorski-get-interactive profile)
    `(progn
       (defvar ,(intern (format "nav-%s-profile" profile-name)) ',profile)

       (define-minor-mode ,(intern (format "%s-terminal-mode" profile-name))
         ,(format "Minor mode for navorski terminal `%s'." profile-name)
         nil
         :group `,(intern (format "%s-navorski-terminal" profile-name))
         :keymap (make-sparse-keymap))

       ;; nav/<profile-name>-get-buffer
       (defun ,(intern (format "nav/%s-get-buffer" profile-name)) ()
         (-navorski-get-buffer ',profile))

       ;; nav/<profile-name>-pop-to-buffer
       (defun ,(intern (format "nav/%s-pop-to-buffer" profile-name)) ()
         (interactive)
         (nav/pop-to-buffer ',profile))

       ;; nav/<profile-name>-send-region
       (defun ,(intern (format "nav/%s-send-region" profile-name)) (start end)
         (interactive "r")
         (nav/send-region ',profile start end))

       ;; nav/<profile-name>-send-string
       (defun ,(intern (format "nav/%s-send-string" profile-name)) (raw-str)
         (interactive ,(format "sSend to %s: " profile-name))
         (nav/send-string ',profile raw-str))

       ;; nav/<profile-name>-kill-buffer
       (defun ,(intern (format "nav/%s-kill-buffer" profile-name)) ()
         (interactive)
         (nav/kill-buffer ',profile t)))))

(defmacro nav/defterminal (profile-name &rest args)
  "Creates a unique terminal with specified settings.

   Possible settings are:

     - :buffer-name (string)

     The name of the terminal buffer (without surrounding
     *earmufs*), defaults to profile-name if not set.

     - :remote-host (string)

     An SSH address to connect to. (e.g user@host.com)

     - :remote-port (string)

     A different SSH port from the default one (22)

     - :program-path (string)

     A program that you want to execute (instead of /bin/bash)

     - :program-args (string, list[string])

     Program arguments to provide to program
     IMPORTANT: this setting doesn't work on persistent sessions.

     - :screen-session-name (string)

     GNU screen session to use for this terminal.

     - :init-script (string, list[string])

     Sends an initial string to the terminal. If a list of strings is specified
     it will execute each of the lines one at a time.

     - :use-tramp (bool)

     Enables tramp integration.

     - :read-only (bool)

     Specifies if the terminal is read-only (only the output of
     the process is printed on the buffer). This is particularly
     usefull when using an specific program different than a
     shell (e.g an http server, a test suite runner, etc)

     - :cwd (fn)

     Receives the current default-directory and allows you to modify it
     in any way, the result must be the `default-directory` value that
     will be used when creating the terminal process.

     - :interactive (bool)

     When t generates utility interactive functions associated to this
     terminal profile, the functions it generates are:

       * a minor mode called <profile-name>-terminal-mode

       * nav/<profile-name>-get-buffer

         Creates a terminal buffer and returns it.

       * nav/<profile-name>-pop-to-buffer

         Pops the terminal buffer (creates it in case is not existing
         via <profile-name>-create-buffer).

       * nav/<profile-name>-send-string

         Sends a raw string to the terminal buffer, in case it
         exists, otherwise does nothing

       * nav/<profile-name>-send-region

         Sends a region to the terminal buffer, in case it
         exists, otherwise does nothing

       * nav/<profile-name>-kill-buffer

         Kills the buffer for this terminal, in case it exists,
         otherwise does nothing.

  Examples:

  (nav/defterminal remote-irb
    :remote-host vagrant@33.33.33.10
    :program-path \"/usr/local/bin/irb\"
    :interactive t
    :screen-session-name \"irb\"
    :use-tramp nil)

  Generates:
  nav/remote-irb-create-buffer
  nav/remote-irb-pop-to-buffer
  nav/remote-irb-kill-buffer
  nav/remote-irb-send-string
  nav/remote-irb-send-region
  ;;;

  (nav/defterminal root-production
    :remote-host \"root@production-site.com\"
    :screen-session \"root\"
    :interactive t
    :use-tramp t)

  Generates:
  nav/root-production-create-buffer
  nav/root-production-pop-to-buffer
  nav/root-production-kill-buffer
  nav/root-production-send-string
  nav/root-production-send-region"

  (let* ((profile0 (-map (lambda (it) `(,(nth 0 it) . ,(nth 1 it)))
                         (-partition 2 (append (list :profile-name `,profile-name) args))))
         (profile (-navorski-merge-alist
                   '((:unique . t)
                     (:interactive . nil)
                     (:read-only . nil)
                     (:kill-buffer-on-stop . t))
                   profile0)))
    `(progn
       (setq ,profile-name ',profile)
       (-navorski-put-profile ',profile-name ',profile)
       (-navorski-def-interactive ,profile-name ,profile))))

(put 'nav/defterminal 'lisp-indent-function 'defun)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main functions



;;;###autoload
(defun nav/term (&optional profile)
  "Creates a multi-term on current directory"
  (interactive)
  (-navorski-get-raw-buffer (-navorski-merge-alist '((:kill-buffer-on-stop . t)) profile)))

;;;###autoload
(defun nav/remote-term (&optional remote-profile)
  "Creates a multi-term in a remote host. A user + host (e.g
user@host) value will be required to perform the connection."
  (interactive)
  (-navorski-get-raw-buffer
   (-navorski-remote-term-to-local-term
    (-navorski-merge-alist '((:kill-buffer-on-stop . t))
                           remote-profile))))

;;;###autoload
(defun nav/persistent-term (&optional profile)
  "Creates a multi-term inside a GNU screen session. A screen
session name is required."
  (interactive)
  (-navorski-get-raw-buffer
   (-navorski-persistent-term-to-local-term
    (-navorski-merge-alist '((:kill-buffer-on-stop . t))
                           profile))))

;;;###autoload
(defun nav/remote-persistent-term (&optional profile)
  "Creates multi-term buffer on a GNU screen session in a remote
host. A user + host (e.g user@host) value is required as well as
a GNU screen session name."
  (interactive)
  (-navorski-get-raw-buffer
   (-navorski-remote-term-to-local-term
    (-navorski-persistent-term-to-local-term
     (-navorski-merge-alist '((:kill-buffer-on-stop . t))
                            profile)))))

;;;###autoload
(defun nav/setup-tramp ()
  "Setups tramp on a remote terminal"
  (interactive)
  (term-send-raw-string
   (concat
    (-navorski-remote-term-setup-tramp-string)
    "\n")))

;;;###autoload
(defun nav/tramp-to-term ()
  "Creates a terminal from the current TRAMP buffer."
  (interactive)
  (require 'tramp)
  (with-parsed-tramp-file-name default-directory nil
      (nav/remote-term
       `((:kill-buffer-on-stop . t)
         (:remote-host . ,(concat user "@" host))
         (:program-args . (,(concat "-c 'cd " localname " && bash -l'")))))))

;; End:
(provide 'navorski)
;;; navorski.el ends here
