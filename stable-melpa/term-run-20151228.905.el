;;; term-run.el --- Run arbitrary command in terminal buffer

;; Author: 10sr <8slashes+el [at] gmail [dot] com>
;; URL: https://github.com/10sr/term-run-el
;; Package-Version: 20151228.905
;; Package-Commit: 54650dbbabb13cb2a6c0670ff6b24b29717a6a8b
;; Version: 0.1.5
;; Keywords: utility shell command term-mode

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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

;; This package provides two functions to invoke programs with arguments
;; in a buffer which works as a terminal-emulator.


;; term-run-shell-command (command $optional new-buffer-p)

;; Run COMMAND in a terminal buffer.

;; This function is intended mainly to be called interactively and
;; asks the command-line to invoke.

;; If called with prefix argument, this function will generate new
;; terminal buffer for running COMMAND.  Otherwise, always use the buffer named
;; *Term-Run Shell Command*. In this case, the old process in the buffer will be
;; destroyed.


;; term-run (program &optional buffer-or-name &rest args)

;; Run PROGRAM in BUFFER-OR-NAME with ARGS in terminal buffer.

;; If BUFFER-OR-NAME is given, use this buffer.  In this case, old process in
;; the buffer will be destroyed.  Otherwise, new buffer will be generated
;; automatically from PROGRAM.

;; This function returns the buffer where the process starts running.



;;; Code:

(eval-and-compile
  (require 'term))

(defvar term-run-shell-command-history nil
  "History for `term-run-shell-command'.")

;;;###autoload
(defun term-run (program &optional buffer-or-name &rest args)
  "Run PROGRAM in BUFFER-OR-NAME with ARGS in terminal buffer.

If BUFFER-OR-NAME is given, use this buffer.  In this case, old process in the
buffer will be destroyed.  Otherwise, new buffer will be generated automatically
from PROGRAM.

This function returns the buffer where the process starts running."
  (let* ((buf (if buffer-or-name
                  (get-buffer-create buffer-or-name)
                (generate-new-buffer (concat "*"
                                             "Term-Run "
                                             program
                                             "*"))))
         (proc (get-buffer-process buf))
         (dir default-directory))
    (and proc
         (delete-process proc))
    (display-buffer buf)
    (with-current-buffer buf
      (cd dir)
      (set (make-local-variable 'term-scroll-to-bottom-on-output)
           t)
      (let ((inhibit-read-only t))
        (goto-char (point-max))
        (insert "\n")
        (insert (format "[%s] Run '%s' with args %S"
                        dir
                        program
                        args))
        (add-text-properties (point-at-bol)
                             (point-at-eol)
                             '(face bold))
        (insert "\n\n"))
      (term-mode)
      (term-exec buf
                 (concat "term-" program)
                 program
                 nil
                 args)
      (term-char-mode)
      (if (ignore-errors (get-buffer-process buf))
          (set-process-sentinel (get-buffer-process buf)
                                (lambda (proc change)
                                  (with-current-buffer (process-buffer proc)
                                    (term-sentinel proc change)
                                    (goto-char (point-max)))))
        ;; (goto-char (point-max))
        ))
    buf))

;;;###autoload
(defun term-run-shell-command (command &optional new-buffer-p)
  "Run COMMAND in terminal buffer.

If NEW-BUFFER-P is given or called with prefix argument, generate new terminal
buffer for running COMMAND.  Otherwise, use the same buffer.  In this case, old
process in the buffer will be destroyed.

This function returns the buffer where the process starts running."
  (interactive (list (read-shell-command (if current-prefix-arg
                                             "C-u Run program: "
                                           "Run program: ")
                                         nil
                                         'term-run-shell-command-history)
                     current-prefix-arg))
  (let ((buf (if new-buffer-p
                 (let ((cmdname (car (split-string command))))
                   (generate-new-buffer (format "*Term-Run Shell Command<%s>*"
                                                cmdname)))
               (get-buffer-create "*Term-Run Shell Command*")))
        (shell (or explicit-shell-file-name
                   shell-file-name
                   (getenv "SHELL")
                   "/bin/sh")))
    (let ((proc (get-buffer-process buf)))
      (if (and proc
               (called-interactively-p 'any)
               (not (y-or-n-p "A process is already running.  Kill and run this command? ")))
          (message "term-run: Command cancelled by user: \"%s\""
                   command)
        (term-run shell
                  buf
                  shell-command-switch
                  command)))))


(provide 'term-run)

;;; term-run.el ends here
