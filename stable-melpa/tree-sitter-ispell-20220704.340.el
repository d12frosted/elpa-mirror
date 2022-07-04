;;; tree-sitter-ispell.el --- Run ispell on tree-sitter text nodes

;; Copyright © 2022 Erick Navarro
;; Author: Erick Navarro <erick@navarro.io>
;; URL: https://github.com/erickgnavar/tree-sitter-ispell.el
;; Package-Version: 20220704.340
;; Package-Commit: 2efe943dd62096a819b7c2d6b61c93a4f18aeb22
;; Version: 0.1.0
;; SPDX-License-Identifier: GNU General Public License v3.0 or later
;; Package-Requires: ((emacs "25.1") (tree-sitter "0.15.0"))

;;; Commentary:
;; Run spell check against tree-sitter text nodes

;;; Code:

(require 'tree-sitter)
(require 'seq)
(require 'cl-lib)

;;TODO: Add more languages, inspect their grammars and define their text elements
(defcustom tree-sitter-ispell-grammar-text-mapping '((python-mode . (string comment))
                                                     (go-mode . (interpreted_string_literal comment))
                                                     (js-mode . (string template_string comment))
                                                     (json-mode . (string string_content comment))
                                                     (ruby-mode . (string string_content comment))
                                                     (sh-mode . (string comment))
                                                     (c-mode . (string_literal comment))
                                                     (c++-mode . (string_literal comment))
                                                     (css-mode . (string_value comment))
                                                     (elixir-mode . (string comment)))
  "All the supported text elements for each grammar."
  :type '(alist :key-type symbol :value-type sexp)
  :group 'tree-sitter-ispell)

(defun tree-sitter-ispell--get-text-node-at-point ()
  "Get text node at point using predefined major mode options."
  (let ((types (alist-get major-mode tree-sitter-ispell-grammar-text-mapping)))
    (seq-some (lambda (x) (tree-sitter-node-at-pos x (point) t)) types)))

(defun tree-sitter-ispell--run-ispell-on-node (node)
  "Run ispell over the text of the received `NODE'."
  (ispell-region (tsc-node-start-position node) (tsc-node-end-position node)))

;;;###autoload
(defun tree-sitter-ispell-run-at-point ()
  "Run ispell at current point if there is a text node."
  (interactive)
  (when-let ((node (tree-sitter-ispell--get-text-node-at-point)))
    (tree-sitter-ispell--run-ispell-on-node node)))

(provide 'tree-sitter-ispell)

;;; tree-sitter-ispell.el ends here
