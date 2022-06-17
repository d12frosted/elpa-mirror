;;; scratch-ext.el --- Extensions for *scratch* -*- lexical-binding: t -*-

;; Copyright: (C) 2012-2014 Kouhei Yanagita
;; Author: Kouhei Yanagita <yanagi@shakenbu.org>
;; URL: https://github.com/kyanagi/scratch-ext-el
;; Package-Version: 20220617.132
;; Package-Commit: 8bbe1649503bb2e3676643e6e49fde155c1d6c70
;; Package-Requires: ((emacs "24.1"))
;; Version: 0.1.0alpha

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the MIT License.

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:
;;
;; scratch-ext.el is extensions for *scratch* buffer.
;;
;; This enables you to dump *scratch* buffer automatically
;; when it is killed or Emacs quits.
;;
;; In addition,
;; * killing *scratch* becomes simply (erase-buffer) it.
;;   So you can easily undo it.
;; * After you save *scratch* to file by hand, new *scratch* buffer is created.
;;

;;; Usage:
;;
;; Add following line to your start up file:
;;
;;     (require 'scratch-ext)
;;
;; Log file goes to ~/.scratch directory by default. You can change this
;; by customizing `scratch-ext-log-directory'.
;;
;; You can bind a key for `scratch-ext-insert-newest-log' and
;; `scratch-ext-restore-last-scratch' if you prefer:
;;
;;     (global-set-key (kbd "C-c i") 'scratch-ext-insert-newest-log)
;;     (global-set-key (kbd "C-c r") 'scratch-ext-restore-last-scratch)
;;

;;; Code:

(defcustom scratch-ext-log-directory (locate-user-emacs-file "scratch" ".scratch")
  "Name of directory where log files go.
If nil, scratch buffer is not saved."
  :type 'string
  :group 'scratch-ext)

(defcustom scratch-ext-log-name-format "%Y/%m/%d-%H%M%S"
  "File name format of scratch log.
Special characters of `format-time-string' are considered.
If nil, scratch buffer is not saved."
  :type 'string
  :group 'scratch-ext)

(defcustom scratch-ext-text-ignore-regexp "\\`[ \t\r\n]*\\'"
  "A regexp to which the *scratch* buffer is not saved when its text is matched."
  :type 'string
  :group 'scratch-ext)

(defun scratch-ext-save-scratch ()
  "Save contents of the *scratch* buffer to a file."
  (when (and scratch-ext-log-directory scratch-ext-log-name-format)
    (let ((file (expand-file-name (format-time-string scratch-ext-log-name-format (current-time))
                                  scratch-ext-log-directory)))
      (scratch-ext--save-scratch-to-file file))))

(defun scratch-ext--save-scratch-to-file (filename)
  "Save contents of the *scratch* buffer to FILENAME."
  (let ((buffer (get-buffer "*scratch*"))
        text)
    (when buffer
      (with-current-buffer buffer
        (setq text (buffer-string))
        (unless (scratch-ext--scratch-text-to-be-discarded-p text)
          (make-directory (file-name-directory filename) t)
          (write-region nil nil filename))))))

(defun scratch-ext--scratch-text-to-be-discarded-p (text)
  "Return non-nil if the *scratch* buffer is not to be saved.
TEXT is contents of the *scratch* buffer."
  (or (string-match-p scratch-ext-text-ignore-regexp text)
      (string= text (or initial-scratch-message ""))))

(defun scratch-ext--clear-scratch ()
  "Clear the *scratch* buffer."
  (scratch-ext--initialize-buffer-as-scratch "*scratch*")
  (message "*scratch* is cleared."))

(defun scratch-ext--initialize-buffer-as-scratch (buffer)
  "Initialize BUFFER as the *scratch* buffer."
  (with-current-buffer buffer
    (funcall initial-major-mode)
    (erase-buffer)
    (when initial-scratch-message
      (insert initial-scratch-message))))

(defun scratch-ext-kill-buffer-query-function ()
  "If the current buffer is the *scratch* buffer, save and clear it."
  (if (string= "*scratch*" (buffer-name))
      (progn
        (scratch-ext-save-scratch)
        (scratch-ext--clear-scratch)
        nil)
    t))

(defun scratch-ext-create-scratch-if-necessary ()
  "Create the *scratch* buffer if not exist."
  (unless (get-buffer "*scratch*")
    (scratch-ext--initialize-buffer-as-scratch (get-buffer-create "*scratch*"))
    (message "New *scratch* is created.")))

(defun scratch-ext--find-newest-log ()
  "Return the name of the newest log file."
  (catch 'found
    (scratch-ext--find-newest-log-1 scratch-ext-log-directory)))

(defun scratch-ext--find-newest-log-1 (dir)
  "Return the name of the newest log file in DIR."
  (let ((entries (nreverse (directory-files dir nil "^[^.]"))))
    (dolist (entry entries)
      (setq entry (expand-file-name entry dir))
      (if (file-directory-p entry)
          (scratch-ext--find-newest-log-1 entry)
        (throw 'found entry)))))

;;;###autoload
(defun scratch-ext-insert-newest-log ()
  "Insert the newest log of the *scratch* buffer."
  (interactive)
  (let ((log (scratch-ext--find-newest-log)))
    (if log
        (insert-file-contents log)
      (message "Log of *scratch* not found."))))

;;;###autoload
(defun scratch-ext-restore-last-scratch ()
  "Restore the last *scratch* buffer to the current buffer."
  (interactive)
  (let ((log (scratch-ext--find-newest-log)))
    (if log
        (progn
          (erase-buffer)
          (insert-file-contents log))
      (message "Log of *scratch* not found."))))


(add-hook 'kill-buffer-query-functions 'scratch-ext-kill-buffer-query-function)
(add-hook 'kill-emacs-hook 'scratch-ext-save-scratch)
(add-hook 'after-save-hook 'scratch-ext-create-scratch-if-necessary)

;;;###autoload
(defun scratch-ext-switch-to-scratch ()
  "Make *scratch* buffer current and display it in selected window."
  (interactive)
  (switch-to-buffer "*scratch*"))


(provide 'scratch-ext)
;;; scratch-ext.el ends here.
