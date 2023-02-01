;;; dmenu.el --- simulate the dmenu command line program

;; Copyright (C) 2004-2015 Free Software Foundation, Inc.

;; Author: DarkSun <lujun9972@gmail.com>
;; Created: 2015-12-01
;; Version: 0.1
;; Package-Version: 20190908.44
;; Package-Commit: e8cc9b27c79d3ecc252267c082ab8e9c82eab264
;; Package-Requires: ((cl-lib "0.5"))
;; Keywords: convenience, usability

;; This file is NOT part of GNU Emacs.

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

;;; Source code
;;
;; dmenu's code can be found here:
;;   http://github.com/lujun9972/el-dmenu

;;; Commentary:

;;; Commentary:

;; Quick start:

;; Bind the following commands:
;; dmenu
;;

;;; Code:

(require 'cl-lib)
(require 'comint)
(defgroup dmenu nil
  "simulate the dmenu command line program."
  :group 'extensions
  :group 'convenience
  :link '(emacs-library-link :tag "Lisp File" "dmenu.el"))

(defcustom dmenu-save-file (locate-user-emacs-file "dmenu-items")
  "File in which the dmenu state is saved between Emacs sessions.
Variables stored are: `dmenu--cache-executable-files', `dmenu--history-list'.
Must be set before initializing Dmenu."
  :type 'string
  :group 'dmenu)

(defcustom dmenu-prompt-string ": "
  "String to display in the dmenu prompt."
  :type 'string
  :group 'dmenu)

(defcustom dmenu-history-size 7
  "Determines on how many recently executed commands dmenu should keep a record. "
  :type 'integer
  :group 'dmenu)

(defvar dmenu-initialized-p nil)

(defvar dmenu--history-list nil)

(defvar dmenu--cache-executable-files nil)

;;;###autoload
(defun dmenu(&optional prefix)
  (interactive "p")
  (unless dmenu-initialized-p
	(dmenu-initialize))
  (unless dmenu--cache-executable-files
	(dmenu--cache-executable-files))
  (let* ((completing-read-fn (if ido-mode
                                 #'ido-completing-read
                               #'completing-read))
         (execute-file (funcall completing-read-fn dmenu-prompt-string
                                        (append dmenu--history-list
                                                (cl-remove-if (lambda (x)
                                                                (member x dmenu--history-list))
                                                              dmenu--cache-executable-files))
                                        nil
                                        'confirm
                                        nil))
         (args (when (= prefix 4)
                 (split-string-and-unquote (read-string "please input the parameters: ")))))
    (if (member (car (split-string execute-file)) dmenu--cache-executable-files)
        (setq dmenu--history-list (cons execute-file
                                        (remove execute-file dmenu--history-list))))
    (cond ((< dmenu-history-size 1)
           (setq dmenu--history-list nil))
          ((> (length dmenu--history-list) dmenu-history-size)
           (setcdr (nthcdr (- dmenu-history-size 1) dmenu--history-list) nil)))
    (switch-to-buffer
      (let* ((cmdlist (split-string-and-unquote execute-file))
             (name execute-file)
             (buffer (generate-new-buffer-name (concat "*" name "*")))
             (program (car cmdlist))
             (switches (append (cdr cmdlist) args))
             (default-directory (if (or (null default-directory)
                                        (file-remote-p default-directory))
                                    "/"
                                  default-directory)))
        (apply #'make-comint-in-buffer name buffer program nil switches))) ;the `default-directory' of `buffer` should not be a remote directory or it will try to execute application in the remote host though TRAMP.
    (set-process-sentinel (get-buffer-process (current-buffer))
                          (lambda (process event)
                            (when (eq 'exit (process-status process))
                              (kill-buffer (process-buffer process)))))))

(defun dmenu-initialize ()
  (dmenu-load-save-file)
  (dmenu-auto-update)
  (add-hook 'kill-emacs-hook 'dmenu-save-to-file)
  (setq dmenu-initialized-p t))

(defun dmenu-load-save-file ()
  "Loads `dmenu--history-list' and `dmenu--cache-executable-files' from `dmenu-save-file'"
  (let ((save-file (expand-file-name dmenu-save-file)))
    (if (file-readable-p save-file)
        (with-temp-buffer
          (insert-file-contents save-file)
          (ignore-errors
            (setq dmenu--cache-executable-files (read (current-buffer)))
            (setq dmenu--history-list (read (current-buffer)))))
      (setq dmenu--history-list nil
            dmenu--cache-executable-files nil))))

(defun dmenu-save-to-file ()
  "Saves `dmenu--history-list' and `dmenu--cache-executable-files' to `dmenu-save-file'"
  (interactive)
  (with-temp-file (expand-file-name dmenu-save-file)
    (prin1 dmenu--cache-executable-files (current-buffer))
    (prin1 dmenu--history-list (current-buffer))))


(defun dmenu--cache-executable-files()
  "Scan $PATH (i.e., `exec-path') for names of executable files and cache them into memory (in variable `dmenu--cache-executable-files')."
  (let* ((valid-exec-path (seq-uniq
                           (cl-remove-if-not #'file-exists-p
                                             (cl-remove-if-not #'stringp exec-path))))
         (files (cl-mapcan (lambda (dir) (directory-files dir t nil nil))
                           valid-exec-path))
         (executable-files (mapcar #'file-name-nondirectory
                                   (cl-remove-if #'file-directory-p
                                                 (cl-remove-if-not #'file-executable-p
                                                                   files)))))
    (setq dmenu--cache-executable-files (seq-uniq (sort executable-files #'string<)))))

(defvar dmenu--update-timer nil)

(defun dmenu-auto-update (&optional idle-time)
  "Update dmenu when Emacs has been idle for IDLE-TIME."
  (let ((idle-time (or idle-time 60)))
    (when dmenu--update-timer
      (cancel-timer dmenu--update-timer))
    (setq dmenu--update-timer (run-with-idle-timer idle-time t #'dmenu--cache-executable-files))))

(provide 'dmenu)

;;; dmenu.el ends here
