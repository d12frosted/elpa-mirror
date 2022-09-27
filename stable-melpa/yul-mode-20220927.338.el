;;; yul-mode.el --- Major mode for editing Ethereum Yul intermediate code

;; Copyright © 2022, by Ta Quang Trung

;; Author: Ta Quang Trung
;; Version: 0.0.2
;; Package-Version: 20220927.338
;; Package-Commit: 56cba05549873fcf1b66e304969011dc1a1ad228
;; Created: 27 September 2022
;; Keywords: languages
;; Homepage: https://github.com/taquangtrung/emacs-yul-mode

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

;; Emacs major mode for editing Yul intermediate code of Ethereum's Solidity
;; smart contracts.

;; Features:
;; - Syntax highlight for Yul intermediate code.
;; - Code outline (labels and blocks) via Imenu.

;; Installation:
;; - Automatic package installation from Melpa.
;; - Manual installation by putting the `yul-mode.el' file in Emacs' load path.

;;; Code:

(require 'rx)
(require 'imenu)

(defconst yul-keywords
  '("break"
    "case"
    "code"
    "continue"
    "data"
    "default"
    "false"
    "for"
    "function"
    "if"
    "leave"
    "let"
    "object"
    "switch"
    "true")
  "List of Yul keywords.")

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Syntax highlighting

(defvar yul-syntax-table
  (let ((syntax-table (make-syntax-table)))
    ;; C++ style comment "// ..."
    (modify-syntax-entry ?\/ ". 124" syntax-table)
    (modify-syntax-entry ?* ". 23b" syntax-table)
    (modify-syntax-entry ?\n ">" syntax-table)
    syntax-table)
  "Syntax table for `yul-mode'.")

(defvar yul-keyword-opcode-regexp
  (concat
   (rx symbol-start)
   (regexp-opt yul-keywords t)
   (rx symbol-end))
  "Regular expression to match Yul keywords.")

(defun yul--match-regexp (re limit)
  "Generic regular expression matching wrapper for RE with a given LIMIT."
  (re-search-forward re
                     limit ; search bound
                     t     ; no error, return nil
                     nil   ; do not repeat
                     ))

(defun yul--match-functions (limit)
  "Search the buffer forward until LIMIT matching function names.
Highlight the 1st result."
  (yul--match-regexp
   (concat
    " *\\([a-zA-Z0-9_$]+\\) *\(")
   limit))

(defconst yul-font-lock-keywords
  (list
   `(,yul-keyword-opcode-regexp . font-lock-keyword-face)
   '(yul--match-functions (1 font-lock-function-name-face)))
  "Font lock keywords of `yul-mode'.")

;;;;;;;;;;;;;;;;;;
;;; Indentation

(defun yul-indent-line (&optional indent)
  "Indent the current line according to the Yul syntax, or supply INDENT."
  (interactive "P")
  (let ((pos (- (point-max) (point)))
        (indent (or indent (yul--calculate-indentation)))
        (shift-amount nil)
        (beg (progn (beginning-of-line) (point))))
    (skip-chars-forward " \t")
    (if (null indent)
        (goto-char (- (point-max) pos))
      (setq shift-amount (- indent (current-column)))
      (unless (zerop shift-amount)
        (delete-region beg (point))
        (indent-to indent))
      (when (> (- (point-max) pos) (point))
        (goto-char (- (point-max) pos))))))

(defun yul--calculate-indentation ()
  "Calculate the indentation of the current line."
  (let (indent)
    (save-excursion
      (back-to-indentation)
      (let* ((ppss (syntax-ppss))
             (depth (car ppss))
             (paren-start-pos (cadr ppss))
             (base (* tab-width depth)))
        (unless (= depth 0)
          (setq indent base)
          (cond ((looking-at "\s*[})]")
                 ;; closing a block or a parentheses pair
                 (setq indent (- base tab-width)))
                ((looking-at "\s*:=")
                 ;; indent for multiple-line assignment
                 (setq indent (+ base (* 2 tab-width))))
                ((looking-back "\s*:=\s*\n\s*")
                 ;; indent for multiple-line assignment
                 (setq indent (+ base (* 2 tab-width))))))))
    indent))

;;;;;;;;;;;;;;;;;;;;;
;;; Imenu settings

(defvar yul--imenu-generic-expression
  '(("Function"
     "^\\s-*function\\s-\\([a-zA-Z0-9_']+\\)\\s-*\("
     1)
    ("Object"
     "^\\s-*object\\s-*\"\\([a-zA-Z0-9_']+\\)\"\\s-*\{"
     1))
  "Regular expression to generate Imenu outline.")

(defun yul--imenu-create-index ()
  "Generate outline of Yul intermediate code for imenu-mode."
  (save-excursion
    (imenu--generic-function yul--imenu-generic-expression)))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Major mode settings

;;;###autoload
(define-derived-mode yul-mode prog-mode
  "yul-mode"
  "Major mode for editing Ethereum Yul intermediate code."
  :syntax-table yul-syntax-table

  ;; Syntax highlighting
  (setq font-lock-defaults '(yul-font-lock-keywords))

  ;; Indentation
  (setq-local indent-tabs-mode nil)
  (setq-local indent-line-function #'yul-indent-line)

  ;; Set comment command
  (setq-local comment-start "//")
  (setq-local comment-end "")
  (setq-local comment-multi-line nil)
  (setq-local comment-use-syntax t)

  ;; Configure imenu
  (setq-local imenu-create-index-function #'yul--imenu-create-index))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.yul\\'" . yul-mode))

;; Finally export the `yul-mode'
(provide 'yul-mode)

;;; yul-mode.el ends here
