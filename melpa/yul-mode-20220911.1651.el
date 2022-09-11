;;; yul-mode.el --- Major mode for editing Ethereum Yul intermediate code

;; Copyright © 2022, by Ta Quang Trung

;; Author: Ta Quang Trung
;; Version: 0.0.1
;; Package-Version: 20220911.1651
;; Package-Commit: 6d5a02ee18145d223a5b0bc46359f1938358b8d4
;; Created: 30 July 2022
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
  (set (make-local-variable 'indent-tabs-mode) nil)
  (set (make-local-variable 'indent-line-function) 'indent-relative)

  ;; Set comment command
  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'comment-multi-line) nil)
  (set (make-local-variable 'comment-use-syntax) t)

  ;; Configure imenu
  (set (make-local-variable 'imenu-create-index-function)
       'yul--imenu-create-index))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.yul\\'" . yul-mode))

;; Finally export the `yul-mode'
(provide 'yul-mode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; yul-mode.el ends here
