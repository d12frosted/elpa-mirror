;;; jvm-mode.el --- Monitor and manage your JVMs -*- lexical-binding: t -*-

;; Copyright (C) 2014 Martin Trojer <martin.trojer@gmail.com>

;; Author: Martin Trojer <martin.trojer@gmail.com>
;; URL: https://github.com/martintrojer/jvm-mode.el
;; Package-Version: 20150422.708
;; Package-Commit: 3355dbaf5b0185aadfbad24160399abb32c5bea0
;; Version: 0.3
;; Package-Requires: ((dash "2.6.0") (emacs "24"))
;; Keywords: convenience

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This global minor mode monitors running JVM on the local system
;; and provides the interactive function "kill-jvms" that
;; kill the jvm processes with match the provided regex.
;; Make sure the JDK command 'jps' in the path.

;; See the README for more info:
;; https://github.com/martintrojer/jvm-mode.el

;;; Code:

(require 'dash)

(defgroup jvm-mode nil
  "Monitor and manage local JVMs")

(defcustom jvm-mode-line-string "jvm[%d]"
  "Mode-line string."
  :type 'string)

(defun jvm-mode-async-shell-command-to-string (command callback)
  "Execute shell command COMMAND asynchronously in the
  background. Invokes CALLBACK with the result string."
  (let ((output-buffer (generate-new-buffer " *temp*"))
        (callback-fun callback))
    (set-process-sentinel
     (start-process "Shell" output-buffer shell-file-name shell-command-switch command)
     (lambda (process signal)
       (when (memq (process-status process) '(exit signal))
         (with-current-buffer output-buffer
           (let ((output-string (buffer-substring-no-properties
                                 (point-min)
                                 (point-max))))
             (funcall callback-fun output-string)))
         (kill-buffer output-buffer))))
    output-buffer))

(defun jvm-mode-get-jvm-pids (callback &optional pattern)
  "Invokes CALLBACK with a list of (matching) JVM pids"
  (let ((pattern (if pattern pattern ""))
        (callback-fun callback))
    (jvm-mode-async-shell-command-to-string
     "jps -l"
     (lambda (out)
       (funcall callback-fun
                (->> (split-string out "\n")
                     (--map (split-string it " "))
                     (--filter (not (string= (car it) "")))
                     (--filter (string-match pattern (cadr it)))
                     (--map (car it))))))))

(defun kill-jvms (&optional pattern)
  "Kills all matching JVMs"
  (interactive "sPattern: ")
  (jvm-mode-get-jvm-pids
   (lambda (pids)
     (--each pids (shell-command-to-string (format "kill %s" it))))
   pattern))

(defvar jvm-mode-string jvm-mode-line-string)

(defun jvm-mode-update-string ()
  (jvm-mode-get-jvm-pids (lambda (all-pids)
                  (setq jvm-mode-string (format jvm-mode-line-string (- (length all-pids) 1))))))

(defvar jvm-mode-timer-object nil)

(defun jvm-mode-start-timer ()
  (setq jvm-mode-timer-object (run-with-timer 0 10 'jvm-mode-update-string)))

(defun jvm-mode-stop-timer ()
  (when jvm-mode-timer-object
    (cancel-timer jvm-mode-timer-object)
    (setq jvm-mode-timer-object nil)))

;;;###autoload
(define-minor-mode jvm-mode
  "Manage your JVMs"
  :global t
  :group 'jvm
  (if jvm-mode
      (progn
        (jvm-mode-start-timer)
        (setq global-mode-string (append global-mode-string '((:eval (list jvm-mode-string))))))
    (progn
      (setq global-mode-string (butlast global-mode-string))
      (jvm-mode-stop-timer))))

(provide 'jvm-mode)

;;; jvm-mode.el ends here
