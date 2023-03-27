;;; lark-mode.el --- Major mode for editing Lark parser code

;; Copyright © 2023, by Ta Quang Trung

;; Author: Ta Quang Trung
;; Version: 0.0.1
;; Package-Version: 20230327.1003
;; Package-Commit: 9e19b40df29d273cf3aec9ddd0e739d3b3d9b3a8
;; Created: 06 March 2023
;; Keywords: languages
;; Homepage: https://github.com/taquangtrung/lark-mode
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

;; Emacs major mode for editing Lark parser code.

;; Features:
;; - Syntax highlight for Lark parser code.
;; - Code outline (labels and blocks) via `Imenu'.

;; Installation:
;; - Automatic package installation from Melpa.
;; - Manual installation by putting the `lark-mode.el' file in Emacs' load path.

;;; Code:

(require 'rx)
(require 'imenu)

(defconst lark-mode-keywords
  '("ignore"
    "import")
  "Lark keywords.")

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Syntax highlighting

(defvar lark-mode-syntax-table
  (let ((syntax-table (make-syntax-table)))
    (modify-syntax-entry ?\/ ". 124" syntax-table)
    (modify-syntax-entry ?* ". 23b" syntax-table)
    (modify-syntax-entry ?\n ">" syntax-table)
    syntax-table)
  "Syntax table for `lark-mode'.")

(defvar lark-mode-keyword-regexp
  (concat
   "%\\s-*"
   (regexp-opt lark-mode-keywords t)
   (rx symbol-end))
  "Regular expression to match Lark keywords.")

(defun lark-mode--match-regexp (re limit)
  "Generic regular expression matching wrapper for RE with a given LIMIT."
  (re-search-forward re
                     limit ; search bound
                     t     ; no error, return nil
                     nil   ; do not repeat
                     ))

(defun lark-mode--match-non-terminal (limit)
  "Search the buffer forward until LIMIT matching non-terminals.
Highlight the 1st result."
  (lark-mode--match-regexp
   (concat
    "^\\s-*\\(_?[a-z][a-zA-Z0-9_]*\\)\\s-*:")
   limit))

(defun lark-mode--match-terminal (limit)
  "Search the buffer forward until LIMIT matching terminals.
Highlight the 1st result."
  (lark-mode--match-regexp
   (concat
    "^\\s-*\\(_?[A-Z][A-Z0-9_]*\\)\\s-*:")
   limit))

(defun lark-mode--match-operator (limit)
  "Search the buffer forward until LIMIT matching operators.
Highlight the 1st result."
  (lark-mode--match-regexp
   (concat
    "\\([\\?\\*\\+%]\\)")
   limit))

(defconst lark-mode-font-lock-keywords
  (list
   `(,lark-mode-keyword-regexp . (1 font-lock-keyword-face))
   '(lark-mode--match-non-terminal (1 font-lock-function-name-face))
   '(lark-mode--match-terminal (1 font-lock-variable-name-face))
   '(lark-mode--match-operator (1 font-lock-constant-face)))
  "Font lock keywords of `lark'.")

;;;;;;;;;;;;;;;;;;
;;; Indentation

(defun lark-mode-indent-line (&optional indent)
  "Indent the current line according to the Lark syntax, or supply INDENT."
  (interactive "P")
  (let ((pos (- (point-max) (point)))
        (indent (or indent (lark-mode--calculate-indentation)))
        (shift-amount nil)
        (beg (point-at-bol)))
    (skip-chars-forward " \t")
    (if (null indent)
        (goto-char (- (point-max) pos))
      (setq shift-amount (- indent (current-column)))
      (unless (zerop shift-amount)
        (delete-region beg (point))
        (indent-to indent))
      (when (> (- (point-max) pos) (point))
        (goto-char (- (point-max) pos))))))

(defun lark-mode--calculate-indentation ()
  "Calculate the indentation of the current line."
  (let (base-indent new-indent)
    (save-excursion
      (back-to-indentation)
      (let* ((ppss (syntax-ppss))
             (bracket-depth (car ppss)))
        ;; Compute base indentation
        (setq base-indent (if (= bracket-depth 0)
                              (save-excursion (forward-line -1)
                                              (back-to-indentation)
                                              (current-indentation))
                            (* tab-width bracket-depth)))
        ;; Compute new indentation
        (cond ((looking-at "\s*[})]")
               ;; closing a block or a parentheses pair
               (setq new-indent (- base-indent tab-width)))
              ((looking-at "\s*:\s*")
               ;; indent for rule definition.
               (setq new-indent (+ base-indent tab-width)))
              ((and (looking-back "\s*:\s*[^\n]*\n\s*" nil nil)
                    (looking-at "\s*|"))
               ;; indent for multiple-line
               (setq new-indent (+ base-indent tab-width)))
              (t (setq new-indent base-indent)))))
    new-indent))

;;;;;;;;;;;;;;;;;;;;;
;;; Imenu settings

(defvar lark-mode--imenu-generic-expression
  '(("Non-terminal"
     "^\\s-*\\(_?[a-z][a-zA-Z0-9_]*\\)\\s-*:.*"
     1)
    ("Terminal"
     "^\\s-*\\(_?[A-Z][A-Z0-9_]*\\)\\s-*:.*"
     1)
    ("Import"
     "^\\s-*import\\s-*\\(_?[A-Z][A-Z0-9_.]*\\)\\s-*:"
     1)
    ("Ignore"
     "^\\s-*ignore\\s-*\\(_?[A-Z][A-Z0-9_.]*\\)\\s-*:"
     1))
  "Regular expression to generate `Imenu' outline.")

(defun lark-mode--imenu-create-index ()
  "Generate outline of Lark code for `Imenu.'."
  (save-excursion
    (imenu--generic-function lark-mode--imenu-generic-expression)))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Major mode settings

;;;###autoload
(define-derived-mode lark-mode prog-mode
  "lark-mode"
  "Major mode for editing Lark parser code."
  :syntax-table lark-mode-syntax-table

  ;; Syntax highlighting
  (setq font-lock-defaults '(lark-mode-font-lock-keywords))

  ;; Indentation
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode nil)
  (setq-local indent-line-function #'lark-mode-indent-line)
  (setq-local indent-region-function #'ignore)      ;; not supported yet

  ;; Set comment command
  (setq-local comment-start "//")
  (setq-local comment-end "")
  (setq-local comment-multi-line nil)
  (setq-local comment-use-syntax t)

  ;; Configure imenu
  (setq-local imenu-create-index-function #'lark-mode--imenu-create-index))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lark\\'" . lark-mode))

;; Finally export the `lark-mode'
(provide 'lark-mode)

;;; lark-mode.el ends here
