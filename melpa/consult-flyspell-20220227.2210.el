;;; consult-flyspell.el --- Consult integration for flyspell  -*- lexical-binding: t; -*-

;; Copyright (C) 2021

;; Author:  Marco Pawłowski
;; Keywords: convenience
;; Package-Version: 20220227.2210
;; Package-Commit: 2e7b99dec6c51259d0bffbae3e863f4054dd2346
;; Version: 0.5
;; Package-Requires: ((emacs "25.1") (consult "0.12"))
;; URL: https://gitlab.com/OlMon/consult-flyspell

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

;; This package provides displaying all misspelled words in the buffer
;; with consult.

;; With the variable `consult-flyspell-select-function' it is possible to apply a function
;; after choosing a candidate.
;; Two possibilities are:
;; (setq consult-flyspell-correct-function 'flyspell-correct-at-point)
;; To correct word directly with `flyspell-correct-word'.

;; (setq consult-flyspell-correct-function (lambda () (flyspell-correct-at-point) (consult-flyspell)))
;; To correct word directly with `flyspell-correct-word' and jump back to `consult-flyspell'.


;;; Code:
(require 'thingatpt)
(require 'flyspell)
(require 'consult)

(defgroup consult-flyspell nil
  "Consult wrapper for flyspell."
  :group 'convenience
  :group 'flymake
  :prefix "consult-flyspell-")

(defface consult-flyspell-line-number
  '((t :inherit compilation-warning))
  "Face used to display the line number of the error.")

(defface consult-flyspell-found-error
  '((t :inherit bold))
  "Face used for the misspelled word.")


(defvar consult-flyspell-select-function nil
  "Function to call after selecting a misspelled word.")

(defvar consult-flyspell-set-point-after-word t
  "Variable to set point after or before word.  Set to nil to place point before word.")

(defvar consult-flyspell-always-check-buffer nil
  "When t calls `flyspell-buffer' every time `consult-flyspell' is called.")

(defun consult-flyspell--all-words ()
  "Collects all currently labeled misspelled words and corresponding point in buffer."
  (reverse (let ((wwords (list)))
             (save-excursion (goto-char (point-min))
                             (save-restriction
                               (widen)
                               (while (not (flyspell-goto-next-error))
                                 (when (word-at-point (point))
                                   (push
                                    `(,(format (format (propertize "Line %%%dd:%s" 'face 'consult-flyspell-line-number)
                                                       (length (number-to-string
                                                                (count-lines (point-min) (point-max))))
                                                       (propertize " %s" 'face 'consult-flyspell-found-error))
                                               (line-number-at-pos (point))
                                               (word-at-point (point)))
                                      ,(point-marker))
                                    wwords))
                                 (forward-word))))
             wwords)))

;;;###autoload
(defun consult-flyspell (&optional u)
  "Display all misspelled words in the current buffer.
If called with prefix U  or `consult-flyspell-always-check-buffer' set to t
will check buffer with `flyspell-buffer' first."
  (interactive "P")
  (when (xor u consult-flyspell-always-check-buffer)
    (flyspell-buffer))
  (let ((candidates (consult--with-increased-gc (consult-flyspell--all-words))))
    (when candidates
      (consult--read
       candidates
       :prompt "Found Errors: "
       :require-match t
       :history t ;; disable history
       :sort nil
       :lookup (lambda (notused candidates cons) (car (consult--lookup-cdr notused candidates cons)))
       :state (consult--jump-state 'consult-preview-error))
      (when (boundp 'consult-flyspell-select-function)
        (funcall consult-flyspell-select-function))
      (if consult-flyspell-set-point-after-word
          (forward-word)
        (forward-char)))))

(provide 'consult-flyspell)
;;; consult-flyspell.el ends here
