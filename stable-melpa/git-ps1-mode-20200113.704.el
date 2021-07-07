;;; git-ps1-mode.el --- Global minor-mode to print __git_ps1 in mode-line

;; Author: 10sr <8slashes+el [at] gmail [dot] com>
;; URL: https://github.com/10sr/git-ps1-mode-el
;; Package-Version: 20200113.704
;; Package-Commit: 6762a309bd593d26258dfbf43e7bc21254a70fbf
;; Version: 0.2.2
;; Keywords: utility mode-line git

;; Contributor: acple <silentsphere110@gmail.com>

;; This file is not part of GNU Emacs.

;; Copyright (C) 2015 by 10sr <8slashes+el [at] gmail [dot] com>
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.


;;; Commentary:

;; Global minor-mode to print `__git_ps1` in mode-line.

;; This minor-mode will print current `git` status in Emacs mode-line as a
;; mode-name. Status text will be generated using `__git_ps1`, which is usually
;; defined in `"git-prompt.sh"`. By default, the text should be like
;; `"[GIT:master *]"`.


;; User Configuration Variables
;; ----------------------------

;; * `git-ps1-mode-lighter-text-format`

;;   Format string for `git-ps1-mode` lighter (mode-name). By default it is set
;;   to `" [GIT:%s]"`.

;; * `git-ps1-mode-ps1-file`

;;   File path to the script that has `__git_ps1` definition.
;;   When set to nil, try to find the definition automatically.

;; * `git-ps1-mode-showdirtystate`
;; * `git-ps1-mode-showstashstate`
;; * `git-ps1-mode-showuntrackedfiles`
;; * `git-ps1-mode-showupstream`

;;   Values for `GIT_PS1_SHOWDIRTYSTATE`, `GIT_PS1_SHOWSTASHSTATE`,
;;   `GIT_PS1_SHOWUNTERACKEDFILES` and `GIT_PS1_SHOWUPSTREAM` respectively.
;;   These variables configure output of `__git_ps1`: see document in
;;   "git-prompt.sh" file for details.

;; * `git-ps1-mode-idle-interval`

;;   If Emacs is idle for this seconds, this mode will update the status text.
;;   By default it is set to `2`.


;;; Code:

;; TODO: Use same status text if `git rev-parse --show-toplevel` is same

(require 'cl-lib)

(defgroup git-ps1-mode nil
  "Global minor-mode to print __git_ps1."
  :group 'tools)

(defcustom git-ps1-mode-ps1-file
  nil
  "File path that contains \"__git_ps1\" definition.
If set to nil, try to find the definition from
 `git-ps1-mode-ps1-file-candidates-list' by `git-ps1-mode-find-ps1-file'."
  :group 'git-ps1-mode
  :type 'string)

;; variables to configure __git_ps1
(defcustom git-ps1-mode-showdirtystate
  (getenv "GIT_PS1_SHOWDIRTYSTATE")
  "Value of GIT_PS1_SHOWDIRTYSTATE when running __git_ps1."
  :group 'git-ps1-mode
  :type 'string)

(defcustom git-ps1-mode-showstashstate
  (getenv "GIT_PS1_SHOWSTASHSTATE")
  "Value of GIT_PS1_SHOWSTASHSTATE when running __git_ps1."
  :group 'git-ps1-mode
  :type 'string)

(defcustom git-ps1-mode-showuntrackedfiles
  (getenv "GIT_PS1_SHOWUNTRACKEDFILES")
  "Value of GIT_PS1_SHOWUNTRACKEDFILES when running __git_ps1."
  :group 'git-ps1-mode
  :type 'string)

(defcustom git-ps1-mode-showupstream
  (getenv "GIT_PS1_SHOWUPSTREAM")
  "Value of GIT_PS1_SHOWUPSTREAM when running __git_ps1."
  :group 'git-ps1-mode
  :type 'string)


(defcustom git-ps1-mode-lighter-text-format " [GIT:%s]"
  "Format for `git-ps1-mode' lighter.
String \"%s\" will be replaced with the output of \"__git_ps1 %s\"."
  :group 'git-ps1-mode
  :type 'string)


(defcustom git-ps1-mode-idle-interval 2
  "If Emacs is idle for this seconds `git-ps1-mode' will update lighter text."
  :group 'git-ps1-mode
  :type 'number)


(defvar git-ps1-mode-ps1-file-candidates-list
  '(
    "/Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-prompt.sh"
    "/usr/share/git/completion/git-prompt.sh"
    "/opt/local/share/doc/git-core/contrib/completion/git-prompt.sh"
    "/etc/bash_completion.d/git"
    "/etc/bash_completion.d/git-prompt"
    "/opt/local/share/git-core/git-prompt.sh"
    "/opt/local/etc/bash_completion.d/git"
    )
  "List of candidates that may contain \"__git_ps1\" definition.")

(defvar git-ps1-mode--ps1-file-candidates-found
  nil
  "Script with __git_ps1 definition.
This variable is used when `git-ps1-mode-ps1-file' is set to nil.")


(defvar git-ps1-mode-process nil
  "Existing process object or nil.")
(make-variable-buffer-local 'git-ps1-mode-process)

(defvar git-ps1-mode-lighter-text
  ""
  "Lighter text for `git-ps1-mode'.  This variable is for internal usage.")
(make-variable-buffer-local 'git-ps1-mode-lighter-text)

(defvar git-ps1-mode-idle-timer-object nil
  "Idle timer object returned from `run-with-idle-timer'.")

(defvar git-ps1-mode-bash-executable
  (executable-find "bash")
  "Path to bash executable.")



;; Functions

(defun git-ps1-mode-ps1-available-p (f)
  "Return F if F exists and it contain function \"__git_ps1\"."
  (and (file-readable-p f)
       (with-temp-buffer
         (insert ". " (shell-quote-argument f) "; "
                 "__git_ps1 %s;")
         (= 0 (shell-command-on-region (point-min)
                                       (point-max)
                                       (concat git-ps1-mode-bash-executable
                                               " -s")
                                       nil
                                       t)))
       f))

(defun git-ps1-mode-find-ps1-file (&optional list)
  "Find file that contain \"__git_ps1\" definition from LIST.
This function returns the path of the first file foundor nil if none.  If LIST
 if omitted `git-ps1-mode-ps1-file-candidates-list' will be used."
  (let ((default-directory (convert-standard-filename "/")))
    (let ((l (or list
                 git-ps1-mode-ps1-file-candidates-list)))
      (and l
           (if (git-ps1-mode-ps1-available-p (car l))
               (car l)
             (and (cdr l)
                  (git-ps1-mode-find-ps1-file (cdr l))))))))


(defun git-ps1-mode-run-process (buffer force)
  "Run git process in BUFFER and get branch name.
Set FORCE to non-nil to skip buffer check."
  (when (or (and force
                 (buffer-live-p buffer))
            (eq buffer (current-buffer)))
    (with-current-buffer buffer
      (unless git-ps1-mode-process
        (let ((default-directory (cl-loop with d = default-directory
                                          until (file-directory-p d)
                                          do (setq d (expand-file-name (concat d "/..")))
                                          finally return d))
              (process-environment `(,(concat "GIT_PS1_SHOWDIRTYSTATE="
                                              (or git-ps1-mode-showdirtystate
                                                  ""))
                                     ,(concat "GIT_PS1_SHOWSTASHSTATE="
                                              (or git-ps1-mode-showstashstate
                                                  ""))
                                     ,(concat "GIT_PS1_SHOWUNTRACKEDFILES="
                                              (or git-ps1-mode-showuntrackedfiles
                                                  ""))
                                     ,(concat "GIT_PS1_SHOWUPSTREAM="
                                              (or git-ps1-mode-showupstream
                                                  ""))
                                     ,@process-environment))
              (process-connection-type nil))
          (setq git-ps1-mode-process
                (start-process "git-ps1-mode"
                               buffer
                               git-ps1-mode-bash-executable
                               "-s"))
          (set-process-filter git-ps1-mode-process
                              'git-ps1-mode-update-modeline)
          (set-process-sentinel git-ps1-mode-process
                                'git-ps1-mode-clear-process)
          (set-process-query-on-exit-flag git-ps1-mode-process
                                          nil)
          (process-send-string git-ps1-mode-process
                               (format ". %s; __git_ps1 %s"
                                       (shell-quote-argument
                                        (or git-ps1-mode-ps1-file
                                            git-ps1-mode--ps1-file-candidates-found))
                                       "%s"))
          (process-send-eof git-ps1-mode-process))))))

(defun git-ps1-mode-update-modeline (process output)
  "Format output of `git-ps1-mode-run-process' and update modeline.
This function is passed as an argument for `set-process-filter': see
document of that function for details about PROCESS and OUTPUT."
  (when (buffer-live-p (process-buffer process))
    (with-current-buffer (process-buffer process)
      (setq git-ps1-mode-lighter-text
            (format git-ps1-mode-lighter-text-format
                    output))
      (force-mode-line-update))))

(defun git-ps1-mode-clear-process (process state)
  "Clear exitted process.
This function is passed as an argument for `set-process-sentinel': see
document of that function for details about PROCESS and STATE."
  (when (buffer-live-p (process-buffer process))
    (with-current-buffer (process-buffer process)
      (setq git-ps1-mode-process nil))))



;; For after-change-major-mode-hook, after-save-hook,
;; window-configuration-change-hook, run-with-idle-timer
(defun git-ps1-mode-update-current ()
  "Update status text immediately."
  (interactive)
  (walk-windows
   (lambda (win)
     (let ((buf (window-buffer win)))
       (unless (minibufferp buf)
         (git-ps1-mode-schedule-update buf t))))))

(defun git-ps1-mode-schedule-update (buffer &optional force)
  "Register process execution timer.
Arguments BUFFER and FORCE will be passed to `git-ps1-mode-run-proess'."
  (with-current-buffer buffer
    (when (and (or git-ps1-mode-ps1-file
                   git-ps1-mode--ps1-file-candidates-found)
               (file-directory-p default-directory))
      (run-with-idle-timer
       0.0 nil #'git-ps1-mode-run-process buffer force))))




;; Minor-mode and user functions

;;;###autoload
(define-minor-mode git-ps1-mode
  "Minor-mode to print __git_ps1."
  :global t
  :lighter (:eval git-ps1-mode-lighter-text)
  (if git-ps1-mode
      (progn
        (setq git-ps1-mode--ps1-file-candidates-found
              (git-ps1-mode-find-ps1-file))
        (git-ps1-mode-update-current)
        (add-hook 'after-change-major-mode-hook
                  'git-ps1-mode-update-current)
        (add-hook 'after-save-hook
                  'git-ps1-mode-update-current)
        (add-hook 'window-configuration-change-hook
                  'git-ps1-mode-update-current)
        (setq git-ps1-mode-idle-timer-object
              (run-with-idle-timer git-ps1-mode-idle-interval
                                   t
                                   'git-ps1-mode-update-current)))
    (remove-hook 'after-change-major-mode-hook
                 'git-ps1-mode-update-current)
    (remove-hook 'after-save-hook
                 'git-ps1-mode-update-current)
    (remove-hook 'window-configuration-change-hook
                 'git-ps1-mode-update-current)
    (cancel-timer git-ps1-mode-idle-timer-object)
    (setq git-ps1-mode-idle-timer-object
          nil))
  (force-mode-line-update t))

;;;###autoload
(defun git-ps1-mode-get-current (&optional format dir)
  "Return current __git_ps1 execution output as string.

Give FORMAT if you want to specify other than \"%s\".
If optional argument DIR is given, run __git_ps1 in that directory.
This function returns nil if the output is not available for some reasons."
  (let ((gcmpl (or git-ps1-mode-ps1-file
                   git-ps1-mode--ps1-file-candidates-found
                   (setq git-ps1-mode--ps1-file-candidates-found
                         (git-ps1-mode-find-ps1-file))))
        (process-environment `(,(concat "GIT_PS1_SHOWDIRTYSTATE="
                                        (or git-ps1-mode-showdirtystate
                                            ""))
                               ,(concat "GIT_PS1_SHOWSTASHSTATE="
                                        (or git-ps1-mode-showstashstate
                                            ""))
                               ,(concat "GIT_PS1_SHOWUNTRACKEDFILES="
                                        (or git-ps1-mode-showuntrackedfiles
                                            ""))
                               ,(concat "GIT_PS1_SHOWUPSTREAM="
                                        (or git-ps1-mode-showupstream
                                            ""))
                               ,@process-environment))
        (dir (or dir
                 default-directory)))
    (when (and git-ps1-mode-bash-executable
             gcmpl
             (file-readable-p gcmpl)
             (file-directory-p dir))
        (with-temp-buffer
          (cd dir)
          (insert ". " gcmpl
                  "; __git_ps1 "
                  (shell-quote-argument (or format
                                            "%s"))
                  ";")
          (shell-command-on-region (point-min)
                                   (point-max)
                                   (concat (shell-quote-argument git-ps1-mode-bash-executable)
                                           " -s")
                                   nil
                                   t)
          (buffer-substring-no-properties (point-min)
                                          (point-max))))))

(provide 'git-ps1-mode)

;;; git-ps1-mode.el ends here
