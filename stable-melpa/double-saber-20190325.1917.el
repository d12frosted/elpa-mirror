;;; double-saber.el --- Narrow and delete in search buffers.  -*- lexical-binding: t; -*-

;; Author: Daniel Ting <deep.paren.12@gmail.com>
;; URL: https://github.com/dp12/double-saber.git
;; Package-Version: 20190325.1917
;; Package-Commit: 93d9b1ec833a871bde2fd0f78abc269872808048
;; Version: 0.0.3
;; Package-Requires: ((emacs "24.4"))
;; Keywords: double-saber, narrow, delete, sort, tools, convenience, matching

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
;;
;; A minor mode for filtering search buffer output.
;;
;; With double-saber-mode enabled, use "d" to delete words and "x" to narrow.
;;
;; Installation:
;; To load this file, add (require 'double-saber) to your init file.
;;
;; You can configure double-saber for different modes using
;; double-saber-mode-setup. The following is an example for ripgrep.
;;
;;(add-hook 'ripgrep-search-mode-hook
;;          (lambda ()
;;            (double-saber-mode)
;;            (setq-local double-saber-start-line 5)
;;            (setq-local double-saber-end-text "Ripgrep finished")))
;;
;; Setting the start line and end text prevents useful text at those locations
;; from getting deleted.
;;
;; Please see README.md for more documentation, or read it online at
;; https://github.com/dp12/double-saber

;;; Code:
(require 'subr-x) ;; for string-trim

(defvar double-saber-start-line 5)
(defvar double-saber-end-text nil)

;;;
;;; Private functions
;;;
(defun double-saber--start-point ()
  "Determine the start point of the region to act on."
  (save-excursion
    (if double-saber-start-line
      (with-no-warnings
        (goto-line double-saber-start-line))
      (goto-char (point-min)))
    (point)))

(defun double-saber--end-point ()
  "Determine the end point of the region to act on."
  (save-excursion
    (goto-char (point-min))
    (if double-saber-end-text
        (if (search-forward double-saber-end-text nil t)
            (forward-line -1)
          (goto-char (point-max)))
      (goto-char (point-max)))
    (point)))

(defun double-saber--get-regexp (filter)
  "Form a regular expression from FILTER.
If the input consists of multiple strings, use regex-opt to make a regular
expression that matches them. Otherwise, if the input is a single string with no
spaces, return it unchanged as the regular expression."
  (let ((regexp (split-string (string-trim filter) " ")))
    (if (> (length regexp) 1)
        (regexp-opt regexp)
      (car regexp))))

;;;
;;; Public functions
;;;
(defun double-saber-narrow (&optional filter)
  "Narrow the search buffer output using FILTER.
The filter can either be a regular expression with no spaces or a list of
strings. All lines that do not match the regular expression or one of the
strings is deleted."
  (interactive
   (list (read-string "Narrow regex/strings: ")))
  (let ((inhibit-read-only t))
    (buffer-enable-undo)
    (delete-non-matching-lines (double-saber--get-regexp filter)
                               (double-saber--start-point)
                               (double-saber--end-point))))

(defun double-saber-delete (&optional filter)
  "Delete all lines in the buffer using FILTER.
The filter can either be a regular expression with no spaces or a list of
strings. All lines that match the regular expression or one of the strings is
deleted."
  (interactive
   (list (read-string "Delete regex/strings: ")))
  (let ((inhibit-read-only t))
    (buffer-enable-undo)
    (delete-matching-lines (double-saber--get-regexp filter)
                           (double-saber--start-point)
                           (double-saber--end-point))))

(defun double-saber-sort-lines (&optional reverse)
  "Sort lines in the search buffer output.
If the REVERSE flag is true, the lines are sorted in reverse order."
  (interactive)
  (let ((inhibit-read-only t))
    (buffer-enable-undo)
    (sort-lines reverse (double-saber--start-point) (double-saber--end-point))))

(defun double-saber-undo (&optional arg)
  "Undo changes. An optional numeric ARG serves as a repeat count."
  (interactive "P")
  (let ((inhibit-read-only t))
    (if (and (bound-and-true-p undo-tree-mode) (fboundp 'undo-tree-undo))
        (undo-tree-undo arg)
      (undo arg))))

(defun double-saber-redo (&optional arg)
  "Redo changes. An optional numeric ARG serves as a repeat count."
  (interactive "P")
  (let ((inhibit-read-only t))
    (if (and (bound-and-true-p undo-tree-mode) (fboundp 'undo-tree-redo))
        (undo-tree-redo arg)
      (undo arg))))

;; Mode-specific setup
;;;###autoload
(define-minor-mode double-saber-mode
  "Delete/narrow text with regular expressions or multiple keywords."
  :lighter " Dsaber"
  :keymap (let ((keymap (make-sparse-keymap)))
            (define-key keymap (kbd "d") 'double-saber-delete)
            (define-key keymap (kbd "x") 'double-saber-narrow)
            (define-key keymap (kbd "s") 'double-saber-sort-lines)
            (define-key keymap (kbd "u") 'double-saber-undo)
            (define-key keymap (kbd "C-r") 'double-saber-redo)
            (define-key keymap (kbd "C-_") 'double-saber-redo)
            keymap))

(provide 'double-saber)

;;; double-saber.el ends here
