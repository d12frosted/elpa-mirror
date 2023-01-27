;; -*- lexical-binding:t -*-
;;; py-smart-operator.el --- smart-operator for python-mode

;; Copyright © 2015 Rustem Muslimov
;;
;; Author:     Rustem Muslimov <r.muslimov@gmail.com>
;; Version:    0.1.0
;; Package-Version: 20170531.1209
;; Package-Commit: 0c8a66faca4b35158d0b5885472cb75286039167
;; Keywords:   python, convenience, smart-operator
;; Package-Requires: ((s "1.9.0"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Python smart-operator mode aims to insert spaces around operators
;; when it is required. It was develop especially for python and requires
;; python-mode.

;; Add this file to your emacs path, and this lines to emacs initialization script
;; (require 'py-smart-operator)
;; (add-hook 'python-mode-hook 'py-smart-operator-mode)

;;; Code:

(require 's)

(defvar py-smart-operator-operators
  '(
    ;; ( char in-comment in-string in-paren in-global)
    ("+" py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-wrap py-smart-operator-do-wrap)
    ("-" py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-wrap py-smart-operator-do-wrap)
    ("/" py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-wrap py-smart-operator-do-wrap)
    ("*" py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-wrap py-smart-operator-do-wrap)
    ("=" py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-wrap)
    ("," py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-space-after py-smart-operator-do-space-after)
    (":" py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-space-after py-smart-operator-do-nothing)
    ("<" py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-wrap)
    (">" py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-nothing py-smart-operator-do-wrap)
    )
  "Registered operators")


(defun py-smart-operator-wrap-and-define-key (keymap option)
  (define-key keymap (car option)
    (lambda (number) (interactive "p") (dotimes (i number) (py-smart-operator-insert-option option)))))

(defvar py-smart-operator-mode-map
  (let* ((keymap (make-sparse-keymap)))
    (progn
      (dolist (option py-smart-operator-operators)
        (py-smart-operator-wrap-and-define-key keymap option))
      keymap))
  "Update keymap with registered operators")

;;;###autoload
(define-minor-mode py-smart-operator-mode
  "Smart operator mode optimized for python"
  :lighter " PySo" :keymap py-smart-operator-mode-map)

(defun py-smart-operator-insert (arg)
  "Specific insert allow insert a char, or a list like (char N), where N number of
   symbols to decrement."
  (cond
   ((stringp arg) (insert arg))
   ((listp arg)
    (let ((to-delete (nth 1 arg))
          (to-insert (car arg)))
      (progn
        (delete-char to-delete)
        (insert to-insert)))
    )))

(defun py-smart-operator-do-wrap (prev-symbols arg)
  "Decide what to do inside of paren"
  (let ((operator-combinations (mapcar (lambda (x) (format "%s " (car x))) py-smart-operator-operators)))
    (cond
     ((member prev-symbols operator-combinations)
      (progn
        (list (format "%s " arg) -1)))
     ((string= (s-right 1 prev-symbols) " ") (format "%s " arg))
     (t  (format " %s " arg)))
    ))

(defun py-smart-operator-do-nothing (prev-symbols arg)
  (format "%s" arg))

(defun py-smart-operator-do-space-after (prev-symbols arg)
  (if (string= (last prev-symbols) " ") (py-smart-operator-do-nothing prev-symbols arg)
    (format "%s " arg)))

(defun py-smart-operator-insert-option (option)
  "Insert required operator by looking to configuration in operators var"
  (let ((prev (buffer-substring-no-properties (- (point) 2) (point)))
        (arg (car option))
        (context (python-syntax-context-type))
        (do-when-comment (nth 1 option))
        (do-when-string (nth 2 option))
        (do-when-paren (nth 3 option))
        (do-when-global (nth 4 option)))
    (cond
     ((eq context 'comment)
      (py-smart-operator-insert (funcall do-when-comment prev arg)))
     ((eq context 'string)
      (py-smart-operator-insert (funcall do-when-string prev arg)))
     ((eq context 'paren)
      (py-smart-operator-insert (funcall do-when-paren prev arg)))
     (t (py-smart-operator-insert (funcall do-when-global prev arg))))
    ))

(provide 'py-smart-operator)
;;; py-smart-operator.el ends here
