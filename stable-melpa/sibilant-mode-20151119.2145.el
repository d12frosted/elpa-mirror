;;; sibilant-mode.el --- Support for the Sibilant programming language

;; Copyright (C) 2011-2015

;; Author: Jacob Rothstein <hi@jbr.me>
;; Created: Feb 9, 2011
;; Keywords: languages
;; Package-Version: 20151119.2145
;; Package-Commit: 5baf8c3e80ee0736c7298a2a17fb615ba5ac0d2d
;; Homepage: http://sibilantjs.info

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

;; Provides a major mode for the Sibilant programming language.

;; I should mention that I looked at clojure-mode
;; (https://github.com/jochu/clojure-mode) when writing this.

;;; Code:



(eval-when-compile
  (defvar calculate-lisp-indent-last-sexp))

(require 'cl)

(defgroup sibilant-mode nil
  "A mode for Sibilant Lisp"
  :prefix "sibilant-mode-"
  :group 'applications)

(defvar sibilant-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map lisp-mode-shared-map)
    (define-key map (kbd "RET") 'reindent-then-newline-and-indent)
    map)
  "Keymap for Sibilant mode.  Inherits from `lisp-mode-shared-map'.")

(defvar sibilant-mode-syntax-table
  (let ((table (copy-syntax-table emacs-lisp-mode-syntax-table)))
    (modify-syntax-entry ?: "." table)
    (modify-syntax-entry ?, "." table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?/  "." table)
    table))

;;;###autoload
(define-derived-mode sibilant-mode lisp-mode "Sibilant"
  "Major mode for editing Sibilant code - similar to Lisp mode."
  (lisp-mode-variables nil)
  (set (make-local-variable 'lisp-indent-function)
       'sibilant-indent-function)
  (setq font-lock-defaults '(sibilant-font-lock-keywords)))

(defconst sibilant-font-lock-keywords
  '(("(\\(def\\|macro\\)[ \t\n\r]+\\([[:alnum:].*/+<>=!-]+[?!]?\\)[ \t\r\n]+(\\(.*?\\))"
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face)
     (3 font-lock-variable-name-face))
    ("\\(\\(\\^\\|macros\\.\\)[[:alnum:].-]+[?!]?\\)"
     (1 font-lock-function-name-face))
    ("(\\(lambda\\)[[:space:]]+(\\(.*?\\))"
     (1 font-lock-keyword-face)
     (2 font-lock-variable-name-face))
    ("(\\(#\\)(\\(.*?\\))"
     (1 font-lock-keyword-face)
     (2 font-lock-variable-name-face))
    ("(\\(#>\\)"
     (1 font-lock-keyword-face))
    ("(\\(var\\|assign\\|set\\)[ \r\n\t]+\\([[:alnum:].-]+[?!]?\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-variable-name-face))
    ("(\\(thunk\\|if\\|when\\|apply\\|alias-macro\\|concat\\|throw\\|switch\\|each\\|chain\\|try\\|call\\|default\\|do\\)[ \t\r\n)]+"
     (1 font-lock-function-name-face))
    ("&[[:alnum:]]+" . font-lock-keyword-face)
    ("\\(\\.\\.\\.\\)"
     (1 font-lock-keyword-face))
    ("'[[:alnum:].-]+[?!]?" . font-lock-string-face)
    ("(\\([[:alnum:].-]+[?!]?\\)"
     (1 font-lock-constant-face nil t))
    ))


(defun sibilant-indent-function (indent-point state)
  (let ((normal-indent (current-column)))
    (goto-char (1+ (elt state 1)))
    (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
    (let ((function (buffer-substring (point)
                                      (progn (forward-sexp 1) (point))))
          (open-paren (elt state 1))
          method)

      (when (eq "#" function) (setq function 'lambda))
      (when (eq "#>" function) (setq function 'thunk))

      (cond
       ((member (char-after open-paren) '(?\[ ?\{))
        (goto-char open-paren)
        (+ 2 (current-column)))

       ((eq method 'def)
        (lisp-indent-defform state indent-point))

       ((integerp method)
        (lisp-indent-specform method state indent-point normal-indent))

       (method
        (funcall method indent-point state))))))


(defun put-sibilant-indent (sym indent)
  (put sym 'sibilant-indent-function indent))

(defmacro define-sibilant-indent (&rest kvs)
  `(progn
     ,@(mapcar (lambda (x) `(put-sibilant-indent
                        (quote ,(first x)) ,(second x))) kvs)))

(define-sibilant-indent
  (lambda 'def)
  (def 'def)
  (macro 'def)
  (if 1)
  (when 1)
  (while 1)
  (try 0)
  (switch 1)
  (progn 0)
  (do 0)
  (scoped 0)
  (for 1)
  (chain 1)
  (each 2)
  (thunk 0))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sib\\(?:ilant\\)?$" . sibilant-mode))
(add-to-list 'auto-mode-alist '("\\.son$" . sibilant-mode))

(provide 'sibilant-mode)

;; Local Variables:
;; coding: utf-8
;; byte-compile-warnings: (not cl-functions)
;; End:

;;; sibilant-mode.el ends here
