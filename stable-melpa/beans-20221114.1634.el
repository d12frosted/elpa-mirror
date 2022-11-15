;;; beans.el --- Major mode for Beans grammar -*- lexical-binding: t; -*-

;; Version: 1
;; Package-Version: 20221114.1634
;; Package-Commit: 0d04b79222812aa4978b6486a9ccac461850fe7a
;; URL: https://github.com/TheBlackBeans/emacs-beans
;; Package-Requires: ((emacs "24.3"))
;; SPDX-License-Identifier: MIT OR GPL-3.0-or-later

;;; Commentary:
;; Defines two major modes, one for editing lexer grammar files, one for editing
;; regular parser grammar files.

;;; Code:

(eval-when-compile
  (require 'rx))

(defconst beans-grammar--font-lock-defaults
  (let ((builtins '("::=" "." "@"))
	(keywords '("left-assoc" "right-assoc")))
    `((("[[:upper:]]+\\b" 0 font-lock-constant-face)
       ("[[:upper:]][[:word:]]*" 0 font-lock-type-face)
       ("\\([[:word:]]+\\)[[:space:]]*:[[:space:]]*[[:word:]]" 1 font-lock-variable-name-face)
       ("^@" 0 font-lock-keyword-face)
       ("\\([[:word:]]+\\)[[:space:]]*\\[" 1 font-lock-preprocessor-face)
       ("\"\([^\"\\\\]\|\\\\[^\\\\]\|\\\\\\\\\)*\"" 0 font-lock-string-face)
       (,(rx-to-string `(: (or ,@keywords))) 0 font-lock-keyword-face)
       (,(rx-to-string `(: (or ,@builtins))) 0 font-lock-builtin-face)))))

(defvar beans-grammar-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\] ")[" st)
    (modify-syntax-entry ?\{ "(}" st)
    (modify-syntax-entry ?\} "){" st)
    (modify-syntax-entry ?\< "(>" st)
    (modify-syntax-entry ?\> ")<" st)
    (modify-syntax-entry ?\" "\"" st)
    st))

(defconst beans-lexer--font-lock-defaults
  `((
     ("^[[:word:] \\t]*?\\(keyword\\)" 1 font-lock-keyword-face)
     ("^[[:word:] \\t]*?\\(ignore\\)" 1 font-lock-keyword-face)
     ("^[[:word:] \\t]*\\(::=\\)" 1 font-lock-builtin-face)
     ("^\\([[:word:] \\t]*[ \\t]\\)?\\([[:word:]]+\\)[ \\t]*::=" 2 font-lock-constant-face))))

;;;###autoload
(define-derived-mode beans-grammar-mode prog-mode "Beans/g"
  "Major mode for Beans grammar files."
  (setq-local font-lock-defaults beans-grammar--font-lock-defaults))

;;;###autoload
(define-derived-mode beans-lexer-mode prog-mode "Beans/l"
  "Major mode for Beans lexer files."
  (setq-local font-lock-defaults beans-lexer--font-lock-defaults))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.gr\\'" . beans-grammar-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lx\\'" . beans-lexer-mode))

(provide 'beans)

;;; beans.el ends here
