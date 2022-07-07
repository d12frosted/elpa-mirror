;;; textx-mode.el --- Major mode for editing TextX files   -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2016 TextX contributors.

;; Author: Novak Boškov <gnovak.boskov@gmail.com>
;; URL: https://github.com/novakboskov/textx-mode
;; Package-Version: 20170516.911
;; Package-Commit: 72f9f0c5855b382024f0da8f56833c22a70a5cb3
;; Keywords: textx
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.3"))

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

;; Basic mode for editing textX code.
;; See <https://github.com/igordejanovic/textX>

;;; Code:

(defgroup textx nil
  "Major mode for editing TextX code."
  :prefix "textx-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/novakboskov/textx-mode"))

(defcustom textx-tab-width 4
  "Tab width in TextX code."
  :type '(integer)
  :group 'textx)

(defconst textx-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?/ ". 124" table)
    (modify-syntax-entry ?* ". 23b" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table)
  "Syntax table used in TextX buffers.")

(defconst textx-keywords '("import"
                           "eolterm"
                           "ws"
                           "skipws"
                           "noskipws"))

(defconst textx-base-types '("BASETYPE"
                             "STRING"
                             "NUMBER"
                             "BOOL"
                             "ID"
                             "INT"
                             "FLOAT"))

(defconst textx-operators '("=" "+=" "*=" "?=" "*" "+" "?" "#"))

(defvar textx-font-lock-keywords
  (list
   (cons (regexp-opt textx-keywords 'words) font-lock-keyword-face)
   (cons (regexp-opt textx-base-types 'words) font-lock-type-face)
   (cons (regexp-opt textx-operators 'symbol) font-lock-keyword-face)))

(defun textx-indent-line ()
  "Indent current line as TextX code."
  (interactive)
  (let ((savep (> (current-column) (current-indentation)))
        (indent (condition-case nil (max (textx-calculate-indentation) 0)
                  (error 0))))
    (if savep
        (save-excursion (indent-line-to indent))
      (indent-line-to indent))))

(defun textx-calculate-indentation ()
  "Calculates desired indentation of a line."
  ;; TODO: This requires deeper analysis.
  (save-excursion
    (beginning-of-line)
    (cond
     ;; Definitions and definitions ends are considered as top level
     ((or (looking-at "^[ \t]*\\([A-Z][a-z0-9]+\\)+:$")
          (looking-at "^[ \t]*;$"))
      0)
     ;; Everything else is indented for one tab.
     (t textx-tab-width))))

(defvar textx-imenu-generic-expression
  ;; Everything that match this regexp is considered as TextX term definition.
  ;; `imenu-generic-expression' works only for top level forms.
  '(("Definition" "^\\([A-Z][a-z0-9]+\\)+:$" 1))
  ;; For more versatile or structured `imenu' a parser function
  ;; `imenu-create-index-function' should be used.
  "Value for `imenu-generic-expression' in TextX mode.")

;;;###autoload
(define-derived-mode textx-mode prog-mode "textX"
  :syntax-table textx-mode-syntax-table
  (setq font-lock-defaults '(textx-font-lock-keywords))
  (setq-local comment-start "// ")
  (setq-local indent-line-function 'textx-indent-line)
  (setq-local imenu-generic-expression textx-imenu-generic-expression))

;; Activate textx-mode for files with .tx extension
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.tx\\'" . textx-mode))

(provide 'textx-mode)

;;; textx-mode.el ends here
