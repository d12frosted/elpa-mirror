;;; sudo-utils.el --- Sudo utilities -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Alpha Catharsis

;; Author: Alpha Catharsis <alpha.catharsis@gmail.com>
;; Maintainer: Alpha Catharsis <alpha.catharsis@gmail.com>
;; Version: 3.0.1
;; Package-Version: 20210119.1930
;; Package-Commit: 089f7833fa256f293284a6286bf9cb2b78eff40d
;; Keywords: processes, unix
;; URL: https://github.com/alpha-catharsis/sudo-utils
;; Package-Requires: ((emacs "25.1"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; sudo-utils provides some useful interactive and non-interactive functions
;; for working with sudo. The package documentation is available here:
;;
;; https://github.com/alpha-catharsis/sudo-utils
;;
;; Please report bugs, requests and suggestions to
;; Alpha Catharsis <alpha.catharsis@gmail.com> or on Github.

;;; Code:

(require 'subr-x)

;; Internal generic functions

(defun sudo-utils--user-shell-abs-path ()
  "Return the absolute path of user shell program.
If the absolute path of the uher shell program cannot be retrieved
from environmental variables then'/bin/sh' is returned."
  (let ((shell (getenv "SHELL")))
    (or shell "/bin/sh")))

(defun sudo-utils--exec-program-sync (program &optional instr &rest args)
  "Run the program PROGRAM with arguments ARGS synchronously.
Returns a list containing the program exit code and output as string.
String INSTR, if not nil, is passed as program standard input."
  (with-temp-buffer
    (list
     (if instr
         (progn
           (insert instr)
           (apply #'call-process-region (point-min) (point-max)
                  program t t nil args))
       (apply #'call-process program nil (current-buffer) nil args))
     (string-trim-right (buffer-string)))))

(defun sudo-utils--exec-program-async (program &optional callback instr
                                               &rest args)
  "Run the program PROGRAM with arguments ARGS asynchronously.
When program terminates the CALLBACK function is called if not nil. The
CALLBACK function receives as arguments the program exit code and output buffer.
String INSTR, if not nil, is passed as program standard input."
  (let ((process
         (make-process
          :name program
          :buffer (generate-new-buffer-name (concat "*" program "*"))
          :command (cons program args)
          :connection-type 'pipe
          :stderr nil
          :sentinel (and callback
                         (lambda (process _event)
                           (let ((exitcode (process-exit-status process))
                                 (buffer (process-buffer process)))
                             (with-current-buffer buffer
                               (funcall callback
                                        exitcode (current-buffer)))))))))
    (when instr
      (process-send-string process (concat instr "\n"))
      (process-send-eof process))))

(defun sudo-utils--shell-command-sync (command &optional instr shell)
  "Run shell command COMMAND with shell SHELL synchronously.
Return a list containing the command exit code and output as string.
String INSTR, if not nil, is passed as command standard input.
If SHELL is not provided, the user default shell is used."
  (apply #'sudo-utils--exec-program-sync
         (list
          (or shell (sudo-utils--user-shell-abs-path)) instr "-c" command)))

(defun sudo-utils--shell-command-async (command &optional callback instr shell)
  "Run the shell command COMMAND with shell SHELL asynchronously.
When command terminates the CALLBACK function is called if not nil. The
CALLBACK function receives as arguments the command exit code and output buffer.
String INSTR, if not nil, is passed as command standard input.
If SHELL is not provided, the user default shell is used."
  (apply #'sudo-utils--exec-program-async
         (list
          (or shell (sudo-utils--user-shell-abs-path))
          callback instr "-c" command)))

(defun sudo-utils--program-abs-path (program)
  "Return the absolute path of program PROGRAM.
It looks also in directories listed in user $PATH environment variable.
If program cannot be found, it returns nil."
  (let ((abs-path
         (if (file-name-absolute-p program)
             program
           (let ((result (sudo-utils--exec-program-sync "which" nil program)))
             (if (= 0 (car result))
                 (cadr result)
               (expand-file-name (cadr result)))))))
    (if (file-exists-p abs-path) abs-path nil)))

;; Internal sudo-utils specific functions

(defun sudo-utils--display-result-cb (exitcode buffer)
  "Handle the result of an asynchronous interactive sudo command.
It utilizes EXITCODE and BUFFER to display the command output in the
other window."
  (with-current-buffer buffer
    (font-lock-mode)
    (when (/= 0 exitcode)
      (font-lock-mode)
      (insert (propertize
               (format "Process exited with error code: %d.\n" exitcode)
               'font-lock-face
               '(:foreground "red"))))
    (if (> (count-lines (point-min) (point-max)) 5)
        (progn
          (read-only-mode)
          (switch-to-buffer-other-window (current-buffer)))
      (progn
        (message (buffer-string))
        (kill-buffer)))))

;; Public functions

(defun sudo-utils-abs-path ()
  "Return the absolute path to sudo."
  (sudo-utils--program-abs-path "sudo"))

(defun sudo-utils-can-run-p ()
  "Check if user can run sudo."
  (let ((sudo-path (sudo-utils-abs-path)))
    (and sudo-path
         (not (string-match-p
               "may not run sudo on"
               (cadr (sudo-utils--exec-program-sync sudo-path nil "-vn")))))))

(defun sudo-utils-can-run-program-p (program &optional password)
  "Check if user can run PROGRAM with sudo.
Return 't if the user can, 'nil if he cannot and, 'unknown if it is not
possible to determine if the user can run the program with sudo. If user
password PASSWORD is provided the result is always known."
  (and (sudo-utils-can-run-p)
       (let* ((flags (if password "-lS" "-ln"))
              (result (sudo-utils--exec-program-sync (sudo-utils-abs-path)
                        password flags program)))
         (if (= 0 (car result))
             t (if (string-match-p "a password is required" (cadr result))
                   'unknown nil)))))

(defun sudo-utils-require-password-p (program &optional password)
  "Check if password is needed for running PROGRAM with sudo.
Return 't if password is required, 'nil if password is not required and
'unknown if it is not possible to determine if password is required.
If user password PASSWORD is provided the result known."
  (let ((cap (sudo-utils-can-run-program-p program password)))
    (cond
     ((eq cap nil)
      (error "User cannot execute program `%s' via sudo" program))
     ((eq cap 'unknown) 'unknown)
     ((eq cap t)
      (let ((cmd-without-passwd
             (alist-get 'nopasswd (sudo-utils-allowed-programs))))
        (not (or (string= (car cmd-without-passwd) "ALL")
                 (member (sudo-utils--program-abs-path program)
                         cmd-without-passwd))))))))

(defun sudo-utils-allowed-programs (&optional password)
    "Return the programs that the user can execute with sudo.
The results is an alist containing with key 'nopasswd the programs that can be
executed without password and with key 'passwd the programs that requiring
password. \"ALL\" indicates that the user can run all programs.
The returned list can be empty of password PASSWORD is not provided."
    (let ((sudo-path (sudo-utils-abs-path))
          (flags (if password "-lS" "-ln")))
      (if sudo-path
          (let ((sudo-result (sudo-utils--exec-program-sync
                              sudo-path password flags))
                (result ()))
            (if (= 0 (car sudo-result))
                (let ((lines (cdr (split-string (cadr sudo-result) "\n" t))))
                  (dolist (line lines result)
                    (let ((fields (split-string line)))
                      (when (or (string= (car fields) "(ALL)")
                                (string= (car fields) "(root)"))
                        (let ((programs
                               (mapcar (lambda (x)
                                         (replace-regexp-in-string "," "" x))
                                       (cdr fields))))
                          (if (string= "NOPASSWD:" (cadr fields))
                              (setq result
                                    (append result
                                            (list
                                             (cons 'nopasswd (cdr programs)))))
                            (setq result
                                  (append result
                                          (list (cons 'passwd programs))))))))))
              nil))
        nil)))

(defun sudo-utils-exec-program-sync (program &optional password &rest args)
  "Execute synchronously program PROGRAM with arguments ARGS as root via sudo.
Returns a list containing the program exit code and output as string.
PASSWORD can be passed as optional argument."
  (let ((flags (if password '("-S") '("-n"))))
    (apply #'sudo-utils--exec-program-sync
           (append
            (list
             (sudo-utils-abs-path)
             password)
            flags `(,program) args))))

(defun sudo-utils-shell-command-sync (command &optional password shell)
  "Execute synchronously shell command COMMAND as root via sudo.
Returns a list containing the program exit code and output as string.
Password PASSWORD can be passed as optional argument.
If SHELL is not provided, the user default shell is used."
  (let ((flags (if password "-S" "-n")))
    (funcall #'sudo-utils--shell-command-sync
           (string-join (list (sudo-utils-abs-path) flags command) " ")
           password
           shell)))

(defun sudo-utils-exec-program-async (program callback &optional password
                                              &rest args)
  "Execute asynchronously program PROGRAM with args ARGS  as root via SUDO.
When program terminates the CALLBACK function is called if not nil. The
CALLBACK function receives as arguments the program exit code and output buffer.
Password PASSWORD can be passed as optional argument."
  (let ((flags (if password '("-S" "-p" "") '("-n"))))
    (apply #'sudo-utils--exec-program-async
           (append
            (list
             (sudo-utils-abs-path)
             callback
             password)
            flags `(,program) args))))

(defun sudo-utils-shell-command-async (command callback &optional
                                               password shell)
  "Execute asynchronously command COMMAND as root via SUDO.
When command terminates the CALLBACK function is called if not nil. The
CALLBACK function receives as arguments the command exit code and output buffer.
Password PASSWORD can be passed as optional argument.
If SHELL is not provided, the user default shell is used."
  (let ((flags (if password "-S -p \"\"" "-n")))
    (funcall #'sudo-utils--shell-command-async
             (string-join (list (sudo-utils-abs-path) flags command) " ")
             callback
             password
             shell)))

(defun sudo-utils-program (program-and-args)
  "Execute program and arguments PROGRAM-AND-ARGS as root via sudo.
The password is requested only if needed."
    (interactive "MProgram and arguments (root): ")
    (let* ((fields (split-string program-and-args))
           (program (car fields))
           (args (cdr fields))
           (path (sudo-utils--program-abs-path program))
           (password nil))
      (if (not (and path
                    (sudo-utils-can-run-program-p path)))
          (error "Cannot exectute program `%s' via sudo" program)
        (when (sudo-utils-require-password-p path)
          (setq password (read-passwd "Enter password: ")))
        (apply #'sudo-utils-exec-program-async
               (append (list path
                             'sudo-utils--display-result-cb password) args)))))

(defun sudo-utils-shell-command (command)
  "Execute command COMMAND as root via sudo.
The password is requested only if needed."
  (interactive "MShell command (root): ")
  (let* ((fields (split-string command))
         (program (car fields))
         (path (sudo-utils--program-abs-path program))
         (password nil))
    (if (not (and path
                  (sudo-utils-can-run-program-p path)))
        (error "Cannot exectute program `%s' via sudo" program)
      (when (sudo-utils-require-password-p path)
        (setq password (read-passwd "Enter password: ")))
      (funcall #'sudo-utils-shell-command-async command
               'sudo-utils--display-result-cb password))))

;; Package provision

 (provide 'sudo-utils)

;;; sudo-utils.el ends here
