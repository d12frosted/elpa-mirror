;;; buffer-wrap.el --- Wrap the beginning and the end of buffer  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Shen, Jen-Chieh
;; Created date 2020-02-22 16:13:15

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Wrap the beginning and the end of buffer.
;; Keyword: buffer tool wrap
;; Version: 0.1.5
;; Package-Version: 20200924.345
;; Package-Commit: db7ab16c98307855e7e258f215703a54911be22c
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/jcs-elpa/buffer-wrap

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Wrap the beginning and the end of buffer.
;;

;;; Code:

(defgroup buffer-wrap nil
  "Wrap the beginning and the end of buffer."
  :prefix "buffer-wrap-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/buffer-wrap"))

(defcustom buffer-wrap-line-changed-hook nil
  "Hooks run every time the line has changed."
  :type 'hook
  :group 'buffer-wrap)

(defcustom buffer-wrap-post-command-hook nil
  "Hooks run every command."
  :type 'hook
  :group 'buffer-wrap)

(defvar-local buffer-wrap--relative-min-line 0
  "Relative line counting from the first line to wrap the buffer.
The default value is 0.")

(defvar-local buffer-wrap--relative-max-line -1
  "Relative line counting from the last line to wrap the buffer.
The default value is -1.")

(defvar-local buffer-wrap--last-current-line -1
  "Record the last current line to see if we need to do wrap.")

(defvar-local buffer-wrap--delta-lines 0
  "Counter of the delta lines between each command.")

(defvar-local buffer-wrap--column -1
  "Record down the column before and after wrapping.")

;;; Entry

(defun buffer-wrap--enable ()
  "Enable 'buffer-wrap-mode."
  (add-hook 'pre-command-hook #'buffer-wrap--pre-command nil t)
  (add-hook 'post-command-hook #'buffer-wrap--post-command nil t)
  (advice-add 'line-move :around #'buffer-wrap--around-line-move))

(defun buffer-wrap--disable ()
  "Disable 'buffer-wrap-mode."
  (remove-hook 'pre-command-hook #'buffer-wrap--pre-command t)
  (remove-hook 'post-command-hook #'buffer-wrap--post-command t)
  (advice-remove 'line-move #'buffer-wrap--around-line-move))

;;;###autoload
(define-minor-mode buffer-wrap-mode
  "Minor mode 'buffer-wrap-mode'."
  :lighter " BW"
  :group 'buffer-wrap
  (if buffer-wrap-mode (buffer-wrap--enable) (buffer-wrap--disable)))

;;; Core

(defun buffer-wrap--goto-line (ln)
  "Goto LN line number."
  (goto-char (point-min))
  (forward-line (1- ln))
  (run-hooks 'buffer-wrap-line-changed-hook))

(defun buffer-wrap--move (ln)
  "Move cursor with LN and COL."
  (buffer-wrap--goto-line ln)
  (when (>= buffer-wrap--column 0) (move-to-column buffer-wrap--column)))

(defun buffer-wrap--around-line-move (fnc &rest args)
  "Post command for `buffer-wrap' with FNC and ARGS."
  (when buffer-wrap-mode
    (setq buffer-wrap--delta-lines
          (+ buffer-wrap--delta-lines (if (listp args) (nth 0 args) args))))
  (if buffer-wrap-mode
      (ignore-errors (apply fnc args))  ; Mute message.
    (apply fnc args)))

(defun buffer-wrap--pre-command ()
  "Pre command for `buffer-wrap'."
  (setq buffer-wrap--last-current-line (line-number-at-pos))
  (setq buffer-wrap--delta-lines 0)
  (setq buffer-wrap--column (current-column)))

(defun buffer-wrap--post-command ()
  "Post command for `buffer-wrap'."
  (let ((current-ln nil)
        (new-current-ln (+ buffer-wrap--last-current-line buffer-wrap--delta-lines))
        (min-ln (+ (line-number-at-pos (point-min)) buffer-wrap--relative-min-line))
        (max-ln (+ (line-number-at-pos (point-max)) buffer-wrap--relative-max-line)))
    (unless (= buffer-wrap--delta-lines 0)
      (cond ((> min-ln new-current-ln)
             (buffer-wrap--move max-ln))
            ((< max-ln new-current-ln)
             (buffer-wrap--move min-ln))))
    (setq current-ln (line-number-at-pos))
    (cond ((< current-ln min-ln)
           (buffer-wrap--move min-ln))
          ((> current-ln max-ln)
           (buffer-wrap--move max-ln))))
  (run-hooks 'buffer-wrap-post-command-hook))

(provide 'buffer-wrap)
;;; buffer-wrap.el ends here
