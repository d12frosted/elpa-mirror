;;; rum-mode.el --- Major mode for Rum programming language

;; Copyright 2017 The Rum Language Authors.  All rights reserve
;; Use of this source code is governed by a MIT
;; license that can be found in the LICENSE file.

;; Authors: Avelino <t@avelino.xxx>
;; URL: https://github.com/rumlang/rum-mode
;; Package-Version: 20180127.22
;; Package-Commit: 161471e6476d232d479f9767535918920811d7bf
;; Version: 1.2
;; Keywords: rum, languages, lisp
;; Package-Requires: ((emacs "24"))
;;
;; This file is not part of GNU Emacs.

;;; Commentary:

;; rum-mode is a major mode for editing code written in Rum
;; Language.

;;; Code:
;; all rum keywords
(defconst rum-keywords
  (regexp-opt
   '("package"
     "breack"
     "continue"
     "for"
     "if"
     "else"
     "import"
     "let"
     "return"
     "struct"
     "case"
     "default"
     "print"
     "sprint"
     "lambda") 'words))

;; all rum functions name
(defconst rum-functions
  (regexp-opt
   '("def") 'words))

;; all rum types name
(defconst rum-types
  (regexp-opt
   '("struct"
     "map"
     "array") 'words))

;; create the list for font-lock.
;; each category of keyword is given a particular face
(defconst rum-font-lock-keywords
  (list
   `(,rum-keywords . font-lock-builtin-face)
   `(,rum-functions . font-lock-function-name-face)
   `(,rum-types . font-lock-type-face)
   `(,"\\<\\(struct\\)\\s-+\\(\\w+\\)\\>"
     (1 font-lock-keyword-face)
     (2 font-lock-type-face))
   `(,"\\<\\(def\\)\\s-+\\(\\w+\\)\\>"
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face))))

;;;###autoload
(define-derived-mode rum-mode lisp-mode "rum"
  "Major mode for editing rum script"
  (set (make-local-variable 'font-lock-defaults) '(rum-font-lock-keywords)))

(add-to-list 'auto-mode-alist '("\\.rum\\'" . rum-mode))

(provide 'rum-mode)
;;; rum-mode.el ends here
