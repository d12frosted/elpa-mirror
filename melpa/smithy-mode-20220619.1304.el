;;; smithy-mode.el --- Major mode for editing Smithy IDL files

;;; Copyright (C) 2022 Matt Nemitz

;; Version: 0.1.3
;; Package-Version: 20220619.1304
;; Package-Commit: 7dff0e7a497a055577226c7ae7ecdeaf7078b4c1
;; Author: Matt Nemitz <matt.nemitz@gmail.com>
;; Maintainer: Matt Nemitz <matt.nemitz@gmail.com>
;; URL: http://github.com/mnemitz/smithy-mode
;; Keywords: tools, languages, smithy, IDL, amazon
;; Package-Requires: ((emacs "26.1"))
;; SPDX-License-Identifier: GPL-3.0-only

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides font-lock for the Smithy IDL (https://awslabs.github.io/smithy/)
;; This may be extended later to more functionality, subject to progress on the
;; Smithy Language Server implementation
;; (https://github.com/awslabs/smithy-language-server)

;;; Code:

;; We leverage the C syntax table to get strings, comments, parentheses and
;; braces matching and highlighting properly
(require 'cc-langs)

(defvar smithy-highlights
  (let* (
         ;; define several category of keywords
         (x-keywords '("namespace" "use" "metadata" "apply" "member"))
         (x-types '("service" "operation" "resource" "map" "structure" "union" "set" "list"))
         (x-simple-type-names'("blob"
                               "boolean"
                               "document"
                               "string"
                               "byte"
                               "short"
                               "integer"
                               "long"
                               "float"
                               "double"
                               "bigInteger"
                               "bigDecimal"
                               "timestamp"))
         (x-node-keywords '("true" "false" "null"))
         ;; generate regex string for each category of keywords
         (x-keywords-regexp (regexp-opt x-keywords 'words))
         (x-traits-regexp "@\\w+\\(\\.\\w+\\)*\\(#\\w+\\)?")
         (x-types-regexp (regexp-opt x-types 'words))
         (x-node-keywords-regexp (regexp-opt x-node-keywords 'words))
         (x-control-statement-regexp "$\\w+:")
         (x-simple-type-names-regexp (regexp-opt x-simple-type-names'words)))
    `(
      (,x-types-regexp . 'font-lock-type-face)
      (,x-simple-type-names-regexp . 'font-lock-builtin-face)
      (,x-keywords-regexp . 'font-lock-keyword-face)
      (,x-node-keywords-regexp . 'font-lock-keyword-face)
      (,x-control-statement-regexp . 'font-lock-preprocessor-face)
      (,x-traits-regexp . 'font-lock-function-name-face))))
;; note: order above matters, because once colored, that part won't change.
;; in general, put longer words first

(defvar smithy-syntax-table
  (let ((table (make-syntax-table)))
    (c-populate-syntax-table table)
    (modify-syntax-entry ?- ". 12b" table)
    table))

;;;###autoload
(define-derived-mode smithy-mode prog-mode "Smithy"
  "Major mode for editing smithy IDL files."
  :syntax-table smithy-syntax-table
  (setq comment-start "// ")
  (setq comment-end "")
  (setq font-lock-defaults '(smithy-highlights)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.smithy\\'" . smithy-mode))

(provide 'smithy-mode)

;;; smithy-mode.el ends here
