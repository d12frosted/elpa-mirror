;;; robots-txt-mode.el --- Major mode for editing robots.txt

;; Copyright (C) 2018 Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 9 Mar 2016
;; Version: 0.0.9
;; Package-Version: 20190812.1858
;; Package-Commit: 8bf67285a25a6756607354d184e36583f2847e7d
;; Keywords: languages, comm, web
;; URL: https://github.com/emacs-php/robots-txt-mode

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

;;; Commentary:

;; This is a major-mode for editing `robots.txt'.

;;; Code:

(defvar robots-txt-mode-directives
  '("Allow"    ; Google
    "Disallow" ; Standard
    "Sitemap")
  "Directive keywords for robots.")

(defvar robots-txt-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?#  "<" table)
    (modify-syntax-entry ?.  "_" table)
    (modify-syntax-entry ?/  "_" table)
    (modify-syntax-entry ?:  "." table)
    (modify-syntax-entry ??  "_" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?_  "_" table)
    table))

(defconst robots-txt-mode-syntax-keywords
  (list
   (cons
    (concat
     "^[ \t]*\\(User-agent[ \t]*:\\)"
     "[ \t]*"
     "\\(\\*\\|[a-zA-Z_-]*\\)"
     "[ \t]*"
     "\\(.*\\)")
    '((1 font-lock-keyword-face)
      (2 font-lock-function-name-face)
      (3 font-lock-warning-face)))
   (cons ; Directive
    (concat
     "^[ \t]*\\(" (regexp-opt robots-txt-mode-directives) "[ \t]*:\\)"
     "[ \t]*"
     "\\(.+\\)")
    '((1 font-lock-type-face)
      (2 font-lock-string-face)))
   (cons ; Non standard directive
    (concat
     "^[ \t]*\\(\\(?:[-a-zA-Z]\\)+[ \t]*:\\)"
     "[ \t]*"
     "\\(.+\\)")
    '((1 font-lock-builtin-face)
      (2 font-lock-string-face)))))

;;;###autoload
(define-derived-mode robots-txt-mode prog-mode "[o_-]"
  "Major mode for editing `robots.txt'"
  :syntax-table robots-txt-mode-syntax-table
  (setq comment-start "# ")
  (setq font-lock-defaults '(robots-txt-mode-syntax-keywords nil t)))

;;;###autoload
(add-to-list 'auto-mode-alist '("/robots\\.txt\\'" . robots-txt-mode))

(provide 'robots-txt-mode)
;;; robots-txt-mode.el ends here
