;;; terminal-here.el --- Run an external terminal in current directory -*- lexical-binding: t; -*-

;; Copyright © 2017 David Shepherd

;; Author: David Shepherd <davidshepherd7@gmail.com>
;; Version: 1.0
;; Package-Version: 20170413.1221
;; Package-Commit: e176d1675dc5c41b6aebd05122fb2efc44b6cff0
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))
;; Keywords: tools, frames
;; URL: https://github.com/davidshepherd7/terminal-here


;;; Commentary:

;; Provides commands to help open external terminal emulators in the
;; directory of the current buffer.


;;; Code:

(require 'cl-lib)


(defgroup terminal-here nil
  "Open external terminal emulators in the current buffer's directory."
  :group 'external
  :prefix "terminal-here-")

(defun terminal-here-default-terminal-command (dir)
  "Pick a good default command to use for DIR."
  (cond
   ((eq system-type 'darwin)
    (list "open" "-a" "Terminal.app" dir))

   ;; From http://stackoverflow.com/a/13509208/874671
   ((memq system-type '(windows-nt ms-dos cygwin))
    (list "cmd.exe" "/C" "start" "cmd.exe"))

   ;; Probably X11!
   (t '("x-terminal-emulator"))))


(defcustom terminal-here-terminal-command
  #'terminal-here-default-terminal-command
  "The command used to start a terminal.

Either a list of strings: (terminal-binary arg1 arg2 ...); or a
function taking a directory and returning such a list."
  :group 'terminal-here
  :type '(choice (repeat string)
                 (function)))

(defcustom terminal-here-project-root-function
  (cl-find-if 'fboundp '(projectile-project-root vc-root-dir))
  "Function called to find the current project root directory.

Good options include `projectile-project-root', which requires
you install the `projectile' package, or `vc-root-dir' which is
available in Emacs >= 25.1.

The function should return nil or signal an error if the current
buffer is not in a project."
  :group 'terminal-here
  :type 'function)



(defun terminal-here-launch-in-directory (dir)
  "Launch a terminal in directory DIR."
  (let* ((term-command (if (functionp terminal-here-terminal-command)
                           (funcall terminal-here-terminal-command dir)
                         terminal-here-terminal-command))
         (process-name (car term-command))
         (default-directory dir)
         (proc (apply #'start-process process-name nil term-command)))
    (set-process-sentinel
     proc
     (lambda (proc _)
       (when (and (eq (process-status proc) 'exit) (/= (process-exit-status proc) 0))
         (message "Error: in terminal here, command `%s` exited with error code %d"
                  (mapconcat #'identity term-command " ")
                  (process-exit-status proc)))))
    ;; Don't close when emacs closes, seems to only be necessary on Windows.
    (set-process-query-on-exit-flag proc nil)))

;;;###autoload
(defun terminal-here-launch ()
  "Launch a terminal in the current working directory.

This is the directory of the current buffer unless you have
changed it by running `cd'."
  (interactive)
  (terminal-here-launch-in-directory default-directory))

;;;###autoload
(defalias 'terminal-here 'terminal-here-launch)

;;;###autoload
(defun terminal-here-project-launch ()
  "Launch a terminal in the current project root.

If projectile is installed the projectile root will be used,
  Otherwise `vc-root-dir' will be used."
  (interactive)
  (when (not terminal-here-project-root-function)
    (signal 'user-error "No `terminal-here-project-root-function' is set."))
  (let ((root (funcall terminal-here-project-root-function)))
    (when (not root)
      (signal 'user-error "Not in any project according to `terminal-here-project-root-function'"))
    (terminal-here-launch-in-directory root)))



(provide 'terminal-here)

;;; terminal-here.el ends here
