;;; tql-mode.el --- TQL mode
;; Copyright (C) 2017 Sean McLaughlin

;; Author: Sean McLaughlin <seanmcl@gmail.com>
;; Version: 0.1
;; Package-Version: 20170724.254
;; Package-Commit: 488add79eb3fc8ec02aedaa997fe1ed9e5c3e638
;; Keywords: languages, TQL
;; Package-Requires: ((emacs "24"))

;;; Commentary:
;; TQL is a language for reasoning about networks.
;; tql-mode gives syntax highlighting and indentation for TQL files.

;;; Code:

(require 'smie)

(defconst tql-mode-highlights
  '(("\\_<[A-Z][-a-zA-Z0-9/_]*" . font-lock-variable-name-face)
    ("\\[\\\([-a-zA-Z0-9/_ ]+\\)\\]" . (1 font-lock-preprocessor-face))
    ("\\(let\\|\\def\\)\s+\\([-a-zA-Z0-9/_]+\\)(" . (2 font-lock-type-face))
    ("\\bdef\\b\\|\\ball\\b\\|\\bex\\b\\|<=>\\|=>\\|&&\\|||\\|\\blet\\b\\|\\bin\\b\\|=" . font-lock-keyword-face)
    ("\\btrue\\b\\|\\bfalse\\b\\|\\blist\\b\\|\\bcount\\b" . font-lock-keyword-face)
    ("\\([-a-zA-Z0-9/_]+\\)(" . (1 font-lock-function-name-face))))

(defvar tql-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap for `tql-mode'.")

(defconst tql-grammar
  (smie-prec2->grammar
   (smie-merge-prec2s
    (smie-bnf->prec2
     '((id)
       (decl (prop ".")
             ("def" prop "=" prop "."))
       (terms (id) (terms "," terms))
       (prop ("all" id ":" prop)
             ("let" prop "=" prop "in" prop)
             ("ex" id ":" prop)
             (prop "<=>" prop)
             (prop "=>" prop)
             (prop "&&" prop)
             (prop "||" prop)
             ("(" prop ")")
             ("(" terms ")")
             (id)))
     '((assoc ","))
     '((assoc ":") (assoc "in") (assoc "<=>") (assoc "=>") (assoc "||") (assoc "&&")))
    )))

(defun tql-rules (kind token)
  "SMIE rules.
KIND: SMIE kind
TOKEN: SMIE token"
  (pcase (cons kind token)
    (`(:after . "in") 0)
    (`(:elem . basic) 2)
    (`(:elem . args) 0)))

(defvar tql-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    table)
  "Syntax table.")

;;;###autoload
(define-derived-mode tql-mode fundamental-mode "tql"
  "Major mode for TQL files."
  (setq font-lock-defaults '(tql-mode-highlights))
  (smie-setup tql-grammar 'tql-rules)
  (set (make-local-variable 'comment-start) "#")
  (set (make-local-variable 'comment-end) ""))


(provide 'tql-mode)

;; Local Variables:
;; lexical-binding: t

;;; tql-mode.el ends here
