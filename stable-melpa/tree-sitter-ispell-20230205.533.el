;;; tree-sitter-ispell.el --- Run ispell on tree-sitter text nodes

;; Copyright © 2022 Erick Navarro
;; Author: Erick Navarro <erick@navarro.io>
;; URL: https://github.com/erickgnavar/tree-sitter-ispell.el
;; Package-Version: 20230205.533
;; Package-Commit: d8c33c05f689c2cab36b8a9856811f18a4ab7c59
;; Version: 0.1.0
;; SPDX-License-Identifier: GNU General Public License v3.0 or later
;; Package-Requires: ((emacs "26.1") (tree-sitter "0.15.0"))

;;; Commentary:
;; Run spell check against tree-sitter text nodes

;;; Code:

(require 'tree-sitter)
(require 'seq)
(require 'cl-lib)

;;TODO: Add more languages, inspect their grammars and define their text elements
(defcustom tree-sitter-ispell-grammar-text-mapping '((python-mode . (string comment))
                                                     (go-mode . (interpreted_string_literal comment))
                                                     (rust-mode . (string_literal line_comment))
                                                     (markdown-mode . (text))
                                                     (clojure-mode . (str_lit comment))
                                                     (sh-mode . (comment string))
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

(defun tree-sitter-ispell--convert-patterns-for-capture (raw-patterns)
  "Convert `RAW-PATTERNS' to capture format."
  (mapconcat 'identity (seq-map (lambda (raw) (format "(%s) @%s" raw raw)) raw-patterns)))

;;;###autoload
(defun tree-sitter-ispell-run-at-point ()
  "Run ispell at current point if there is a text node."
  (interactive)
  (when-let ((node (tree-sitter-ispell--get-text-node-at-point)))
    (tree-sitter-ispell--run-ispell-on-node node)))

;;;###autoload
(defun tree-sitter-ispell-run-buffer ()
  "Run ispell for every text node for the current buffer."
  (interactive)
  ;; we call tree-sitter-tree first because if the current buffer doesn't have support
  ;; it will return nil and that will stop when-let* execution
  (when-let* ((tree tree-sitter-tree)
              (root-node (tsc-root-node tree))
              (raw-patterns (alist-get major-mode tree-sitter-ispell-grammar-text-mapping))
              (patterns (tree-sitter-ispell--convert-patterns-for-capture raw-patterns))
              (query (tsc-make-query tree-sitter-language patterns))
              (captures (tsc-query-captures query root-node #'tsc--buffer-substring-no-properties)))
    (seq-map (lambda (capture) (tree-sitter-ispell--run-ispell-on-node (cdr capture))) captures)))

(provide 'tree-sitter-ispell)

;;; tree-sitter-ispell.el ends here
