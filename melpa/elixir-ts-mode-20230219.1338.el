;;; elixir-ts-mode.el --- Major mode for Elixir with tree-sitter support -*- lexical-binding: t; -*-

;; Copyright (C) 2022, 2023 Wilhelm H Kirschbaum

;; Author           : Wilhelm H Kirschbaum
;; Version          : 1.1
;; Package-Version: 20230219.1338
;; Package-Commit: 9a397f8135468a9ec853a869033946a08d57a1c0
;; URL              : https://github.com/wkirschbaum/elixir-ts-mode
;; Package-Requires : ((emacs "29") (heex-ts-mode "1.1"))
;; Created          : November 2022
;; Keywords         : elixir languages tree-sitter

;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.

;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.

;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package defines elixir-ts-mode which is a major mode for editing
;; Elixir and Heex files.

;; Features

;; * Indent

;; elixir-ts-mode tries to replicate the indentation provided by
;; mix format, but will come with some minor differences.

;; * IMenu
;; * Navigation
;; * Which-fun

;;; Code:

(require 'treesit)
(require 'heex-ts-mode)
(eval-when-compile (require 'rx))

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-node-child "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-node-child-by-field-name "treesit.c")
(declare-function treesit-parser-language "treesit.c")
(declare-function treesit-parser-included-ranges "treesit.c")
(declare-function treesit-parser-list "treesit.c")
(declare-function treesit-node-parent "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-query-compile "treesit.c")
(declare-function treesit-install-language-grammar "treesit.el")

(defcustom elixir-ts-mode-indent-offset 2
  "Indentation of Elixir statements."
  :version "29.1"
  :type 'integer
  :safe 'integerp
  :group 'elixir)

(defface elixir-ts-font-keyword-face
  '((t (:inherit font-lock-keyword-face)))
  "For use with @keyword tag.")

(defface elixir-ts-font-comment-doc-face
  '((t (:inherit font-lock-doc-face)))
  "For use with @comment.doc tag.")

(defface elixir-ts-font-comment-doc-identifier-face
  '((t (:inherit font-lock-doc-face)))
  "For use with @comment.doc tag.")

(defface elixir-ts-font-comment-doc-attribute-face
  '((t (:inherit font-lock-doc-face)))
  "For use with @comment.doc.__attribute__ tag.")

(defface elixir-ts-font-attribute-face
  '((t (:inherit font-lock-preprocessor-face)))
  "For use with @attribute tag.")

(defface elixir-ts-font-operator-face
  '((t (:inherit default)))
  "For use with @operator tag.")

(defface elixir-ts-font-constant-face
  '((t (:inherit font-lock-constant-face)))
  "For use with @constant tag.")

(defface elixir-ts-font-number-face
  '((t (:inherit default)))
  "For use with @number tag.")

(defface elixir-ts-font-module-face
  '((t (:inherit font-lock-type-face)))
  "For use with @module tag.")

(defface elixir-ts-font-punctuation-face
  '((t (:inherit font-lock-keyword-face)))
  "For use with @punctuation tag.")

(defface elixir-ts-font-punctuation-delimiter-face
  '((t (:inherit font-lock-keyword-face)))
  "For use with @punctuation.delimiter tag.")

(defface elixir-ts-font-punctuation-bracket-face
  '((t (:inherit font-lock-keyword-face)))
  "For use with @punctuation.bracket.")

(defface elixir-ts-font-punctuation-special-face
  '((t (:inherit font-lock-variable-name-face)))
  "For use with @punctuation.special tag.")

(defface elixir-ts-font-embedded-face
  '((t (:inherit default)))
  "For use with @embedded tag.")

(defface elixir-ts-font-string-face
  '((t (:inherit font-lock-string-face)))
  "For use with @string tag.")

(defface elixir-ts-font-string-escape-face
  '((t (:inherit font-lock-regexp-grouping-backslash)))
  "For use with Reserved keywords.")

(defface elixir-ts-font-string-regex-face
  '((t (:inherit font-lock-string-face)))
  "For use with @string.regex tag.")

(defface elixir-ts-font-string-special-face
  '((t (:inherit font-lock-string-face)))
  "For use with @string.special tag.")

(defface elixir-ts-font-string-special-symbol-face
  '((t (:inherit font-lock-builtin-face)))
  "For use with @string.special.symbol tag.")

(defface elixir-ts-font-function-face
  '((t (:inherit font-lock-function-name-face)))
  "For use with @function tag.")

(defface elixir-ts-font-sigil-name-face
  '((t (:inherit font-lock-string-face)))
  "For use with @__name__ tag.")

(defface elixir-ts-font-variable-face
  '((t (:inherit default)))
  "For use with @variable tag.")

(defface elixir-ts-font-constant-builtin-face
  '((t (:inherit font-lock-keyword-face)))
  "For use with @constant.builtin tag.")

(defface elixir-ts-font-comment-face
  '((t (:inherit font-lock-comment-face)))
  "For use with @comment tag.")

(defface elixir-ts-font-comment-unused-face
  '((t (:inherit font-lock-comment-face)))
  "For use with @comment.unused tag.")

(defface elixir-ts-font-error-face
  '((t (:inherit error)))
  "For use with @comment.unused tag.")

(defconst elixir-ts-mode-sexp-regexp
  (rx bol
      (or "call" "stab_clause" "binary_operator" "list" "tuple" "map" "pair"
          "sigil" "string" "atom" "pair" "alias" "arguments" "atom" "identifier"
          "boolean" "quoted_content")
      eol))

(defconst elixir-ts-mode--test-definition-keywords
  '("describe" "test"))

(defconst elixir-ts-mode--definition-keywords
  '("def" "defdelegate" "defexception" "defguard" "defguardp"
    "defimpl" "defmacro" "defmacrop" "defmodule" "defn" "defnp"
    "defoverridable" "defp" "defprotocol" "defstruct"))

(defconst elixir-ts-mode--definition-keywords-re
  (concat "^" (regexp-opt elixir-ts-mode--definition-keywords) "$"))

(defconst elixir-ts-mode--kernel-keywords
  '("alias" "case" "cond" "else" "for" "if" "import" "quote"
    "raise" "receive" "require" "reraise" "super" "throw" "try"
    "unless" "unquote" "unquote_splicing" "use" "with"))

(defconst elixir-ts-mode--kernel-keywords-re
  (concat "^" (regexp-opt elixir-ts-mode--kernel-keywords) "$"))

(defconst elixir-ts-mode--builtin-keywords
  '("__MODULE__" "__DIR__" "__ENV__" "__CALLER__" "__STACKTRACE__"))

(defconst elixir-ts-mode--builtin-keywords-re
  (concat "^" (regexp-opt elixir-ts-mode--builtin-keywords) "$"))

(defconst elixir-ts-mode--doc-keywords
  '("moduledoc" "typedoc" "doc"))

(defconst elixir-ts-mode--doc-keywords-re
  (concat "^" (regexp-opt elixir-ts-mode--doc-keywords) "$"))

(defconst elixir-ts-mode--reserved-keywords
  '("when" "and" "or" "not" "in"
    "not in" "fn" "do" "end" "catch" "rescue" "after" "else"))

(defconst elixir-ts-mode--reserved-keywords-re
  (concat "^" (regexp-opt elixir-ts-mode--reserved-keywords) "$"))

(defconst elixir-ts-mode--reserved-keywords-vector
  (apply #'vector elixir-ts-mode--reserved-keywords))

(defvar elixir-ts-mode-default-grammar-sources
  '((elixir . ("https://github.com/elixir-lang/tree-sitter-elixir.git"))
    (heex . ("https://github.com/phoenixframework/tree-sitter-heex.git"))))

(defvar elixir-ts-mode--capture-anonymous-function-end
  (when (treesit-available-p)
    (treesit-query-compile 'elixir '((anonymous_function "end" @end)))))

(defvar elixir-ts-mode--capture-operator-parent
  (when (treesit-available-p)
    (treesit-query-compile 'elixir '((binary_operator operator: _ @val)))))

(defvar elixir-ts-mode--capture-first-argument
  (when (treesit-available-p)
    (treesit-query-compile
     'elixir
     '((arguments :anchor (_) @first-child) (tuple :anchor (_) @first-child)))))

(defvar elixir-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?| "." table)
    (modify-syntax-entry ?- "." table)
    (modify-syntax-entry ?+ "." table)
    (modify-syntax-entry ?* "." table)
    (modify-syntax-entry ?/ "." table)
    (modify-syntax-entry ?< "." table)
    (modify-syntax-entry ?> "." table)
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?? "w" table)
    (modify-syntax-entry ?~ "w" table)
    (modify-syntax-entry ?! "_" table)
    (modify-syntax-entry ?' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?\( "()" table)
    (modify-syntax-entry ?\) ")(" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?: "'" table)
    (modify-syntax-entry ?@ "'" table)
    table)
  "Syntax table for `elixir-ts-mode.")

(defun elixir-ts-mode--call-parent-start (parent)
  (let ((call-parent
         (or (treesit-parent-until
              parent
              (lambda (node)
                (equal (treesit-node-type node) "call")))
             parent)))
    (save-excursion
      (goto-char (treesit-node-start call-parent))
      (back-to-indentation)
      ;; for pipes we ignore the call indentation
      (if (looking-at "|>")
          (point)
        (treesit-node-start call-parent)))))

(defvar elixir-ts-mode--indent-rules
  (let ((offset elixir-ts-mode-indent-offset))
    `((elixir
       ((parent-is "^source$") point-min 0)
       ((parent-is "^string$") parent-bol 0)
       ((parent-is "^quoted_content$")
        (lambda (_n parent bol &rest _)
          (save-excursion
            (back-to-indentation)
            (if (bolp)
                (progn
                  (goto-char (treesit-node-start parent))
                  (back-to-indentation)
                  (point))
              (point)))) 0)
       ((node-is "^]") parent-bol 0)
       ((node-is "^|>$") parent-bol 0)
       ((node-is "^|$") parent-bol 0)
       ((node-is "^}$") parent-bol 0)
       ((node-is "^)$")
        (lambda (_node parent &rest _)
          (elixir-ts-mode--call-parent-start parent))
        0)
       ((node-is "^else_block$") grand-parent 0)
       ((node-is "^catch_block$") grand-parent 0)
       ((node-is "^rescue_block$") grand-parent 0)
       ((node-is "^after_block$") grand-parent 0)
       ((parent-is "^else_block$") parent ,offset)
       ((parent-is "^catch_block$") parent ,offset)
       ((parent-is "^rescue_block$") parent ,offset)
       ((parent-is "^rescue_block$") parent ,offset)
       ((parent-is "^after_block$") parent ,offset)
       ((parent-is "^tuple$") parent-bol ,offset)
       ((parent-is "^list$") parent-bol ,offset)
       ((parent-is "^pair$") parent ,offset)
       ((parent-is "^map_content$") parent-bol 0)
       ((parent-is "^map$") parent-bol ,offset)
       ((node-is "^stab_clause$") parent-bol ,offset)
       ((query ,elixir-ts-mode--capture-operator-parent) grand-parent 0)
       ((node-is "^when$") parent 0)
       ((node-is "^keywords$") parent-bol ,offset)
       ((parent-is "^body$")
        (lambda (node parent _)
          (save-excursion
            ;; the grammar adds a comment outside of the body, so we have to indent
            ;; to the grand-parent if it is available
            (goto-char (treesit-node-start
                        (or (treesit-node-parent parent) (parent))))
            (back-to-indentation)
            (point)))
        ,offset)
       ((parent-is "^arguments$")
        ;; the first argument must indent ,offset from start of call
        ;; otherwise indent should be the same as the first argument
        (lambda (node parent bol &rest _)
          (let ((first-child (treesit-node-child parent 0 t)))
            (if (treesit-node-eq node first-child)
                (elixir-ts-mode--call-parent-start parent)
              (treesit-node-start first-child))))
        (lambda (node parent rest)
          ;; if first-child offset otherwise don't
          (if (treesit-node-eq
               (treesit-node-child parent 0 t)
               node)
              ,offset
            0)))
       ;; handle incomplete maps when parent is ERROR
       ((n-p-gp "^binary_operator$" "ERROR" nil) parent-bol 0)
       ;; When there is an ERROR, just indent to prev-line
       ;; Not sure why it needs one more, but adding it for now
       ((parent-is "ERROR") prev-line 1)
       ((node-is "^binary_operator$")
        (lambda (node parent &rest _)
          (let ((top-level
                 (treesit-parent-while
                  node
                  (lambda (node)
                    (equal (treesit-node-type node)
                           "binary_operator")))))
            (if (treesit-node-eq top-level node)
                (elixir-ts-mode--call-parent-start parent)
              (treesit-node-start top-level))))
        (lambda (node parent _)
          (cond
           ((equal (treesit-node-type parent) "do_block")
            ,offset)
           ((equal (treesit-node-type parent) "binary_operator")
            ,offset)
           (t 0))))
       ((parent-is "^binary_operator$")
        (lambda (node parent bol &rest _)
          (treesit-node-start
           (treesit-parent-while
            parent
            (lambda (node)
              (equal (treesit-node-type node) "binary_operator")))))
        ,offset)
       ((node-is "^pair$") first-sibling 0)
       ((query ,elixir-ts-mode--capture-anonymous-function-end) parent-bol 0)
       ((node-is "^end$")
        (lambda (_node parent &rest _)
          (elixir-ts-mode--call-parent-start parent)) 0)
       ((parent-is "^do_block$") grand-parent ,offset)
       ((parent-is "^anonymous_function$")
        elixir-ts-mode--treesit-anchor-grand-parent-bol ,offset)
       ((parent-is "^else_block$") parent ,offset)
       ((parent-is "^rescue_block$") parent ,offset)
       ((parent-is "^catch_block$") parent ,offset)
       ((parent-is "^keywords$") parent-bol 0)
       ((node-is "^call$") parent-bol ,offset)
       ((node-is "^comment$") parent-bol ,offset)))))

;; reference:
;; https://github.com/elixir-lang/tree-sitter-elixir/blob/main/queries/highlights.scm
(defvar elixir-ts-mode--font-lock-settings
  (when (treesit-available-p)
    (treesit-font-lock-rules
     :language 'elixir
     :feature 'elixir-comment
     '((comment) @elixir-ts-font-comment-face)

     :language 'elixir
     :feature 'elixir-string
     :override t
     '([(string) (charlist)] @font-lock-string-face)

     :language 'elixir
     :feature 'elixir-string-interpolation
     :override t
     '((string
        [
         quoted_end: _ @elixir-ts-font-string-face
         quoted_start: _ @elixir-ts-font-string-face
         (quoted_content) @elixir-ts-font-string-face
         (interpolation
          "#{" @elixir-ts-font-string-escape-face "}"
          @elixir-ts-font-string-escape-face)
         ])
       (charlist
        [
         quoted_end: _ @elixir-ts-font-string-face
         quoted_start: _ @elixir-ts-font-string-face
         (quoted_content) @elixir-ts-font-string-face
         (interpolation
          "#{" @elixir-ts-font-string-escape-face "}"
          @elixir-ts-font-string-escape-face)
         ]))

     :language 'elixir
     :feature 'elixir-keyword
     ;; :override `prepend
     `(,elixir-ts-mode--reserved-keywords-vector
       @elixir-ts-font-keyword-face
       ;; these are operators, should we mark them as keywords?
       (binary_operator
        operator: _ @elixir-ts-font-keyword-face
        (:match ,elixir-ts-mode--reserved-keywords-re @elixir-ts-font-keyword-face)))

     :language 'elixir
     :feature 'elixir-doc
     :override t
     `((unary_operator
        operator: "@" @elixir-ts-font-comment-doc-attribute-face
        operand: (call
                  target: (identifier) @elixir-ts-font-comment-doc-identifier-face
                  ;; arguments can be optional, but not sure how to specify
                  ;; so adding another entry without arguments
                  ;; if we don't handle then we don't apply font
                  ;; and the non doc fortification query will take specify
                  ;; a more specific font which takes precedence
                  (arguments
                   [
                    (string) @elixir-ts-font-comment-doc-face
                    (charlist) @elixir-ts-font-comment-doc-face
                    (sigil) @elixir-ts-font-comment-doc-face
                    (boolean) @elixir-ts-font-comment-doc-face
                    ]))
        (:match ,elixir-ts-mode--doc-keywords-re
                @elixir-ts-font-comment-doc-identifier-face))
       (unary_operator
        operator: "@" @elixir-ts-font-comment-doc-attribute-face
        operand: (call
                  target: (identifier) @elixir-ts-font-comment-doc-identifier-face)
        (:match ,elixir-ts-mode--doc-keywords-re
                @elixir-ts-font-comment-doc-identifier-face)))

     :language 'elixir
     :feature 'elixir-unary-operator
     `((unary_operator operator: "@" @elixir-ts-font-attribute-face
                       operand: [
                                 (identifier)  @elixir-ts-font-attribute-face
                                 (call target: (identifier)
                                       @elixir-ts-font-attribute-face)
                                 (boolean)  @elixir-ts-font-attribute-face
                                 (nil)  @elixir-ts-font-attribute-face
                                 ])

       (unary_operator operator: "&") @elixir-ts-font-function-face
       (operator_identifier) @elixir-ts-font-operator-face)

     :language 'elixir
     :feature 'elixir-operator
     '((binary_operator operator: _ @elixir-ts-font-operator-face)
       (dot operator: _ @elixir-ts-font-operator-face)
       (stab_clause operator: _ @elixir-ts-font-operator-face)

       [(boolean) (nil)] @elixir-ts-font-constant-face
       [(integer) (float)] @elixir-ts-font-number-face
       (alias) @elixir-ts-font-module-face
       (call target: (dot left: (atom) @elixir-ts-font-module-face))
       (char) @elixir-ts-font-constant-face
       [(atom) (quoted_atom)] @elixir-ts-font-module-face
       [(keyword) (quoted_keyword)] @elixir-ts-font-string-special-symbol-face)

     :language 'elixir
     :feature 'elixir-call
     `((call
        target: (identifier) @elixir-ts-font-keyword-face
        (:match ,elixir-ts-mode--definition-keywords-re @elixir-ts-font-keyword-face))
       (call
        target: (identifier) @elixir-ts-font-keyword-face
        (:match ,elixir-ts-mode--kernel-keywords-re @elixir-ts-font-keyword-face))
       (call
        target: [(identifier) @elixir-ts-font-function-face
                 (dot right: (identifier) @elixir-ts-font-function-face)])
       (call
        target: (identifier) @elixir-ts-font-keyword-face
        (arguments
         [
          (identifier) @elixir-ts-font-function-face
          (binary_operator
           left: (identifier) @elixir-ts-font-function-face
           operator: "when")
          ])
        (:match ,elixir-ts-mode--definition-keywords-re @elixir-ts-font-keyword-face))
       (call
        target: (identifier) @elixir-ts-font-keyword-face
        (arguments
         (binary_operator
          operator: "|>"
          right: (identifier) @elixir-ts-font-variable-face))
        (:match ,elixir-ts-mode--definition-keywords-re @elixir-ts-font-keyword-face)))

     :language 'elixir
     :feature 'elixir-constant
     `((binary_operator operator: "|>" right: (identifier)
                        @elixir-ts-font-function-face)
       ((identifier) @elixir-ts-font-constant-builtin-face
        (:match ,elixir-ts-mode--builtin-keywords-re
                @elixir-ts-font-constant-builtin-face))
       ((identifier) @elixir-ts-font-comment-unused-face
        (:match "^_" @elixir-ts-font-comment-unused-face))
       (identifier) @elixir-ts-font-variable-face
       ["%"] @elixir-ts-font-punctuation-face
       ["," ";"] @elixir-ts-font-punctuation-delimiter-face
       ["(" ")" "[" "]" "{" "}" "<<" ">>"] @elixir-ts-font-punctuation-bracket-face)

     :language 'elixir
     :feature 'elixir-sigil
     :override t
     `((sigil
        (sigil_name) @elixir-ts-font-sigil-name-face
        quoted_start: _ @elixir-ts-font-string-face
        quoted_end: _ @elixir-ts-font-string-face
        (:match "^[sSwWpP]$" @elixir-ts-font-sigil-name-face))
       @elixir-ts-font-string-face
       (sigil
        (sigil_name) @elixir-ts-font-sigil-name-face
        quoted_start: _ @elixir-ts-font-string-regex-face
        quoted_end: _ @elixir-ts-font-string-regex-face
        (:match "^[rR]$" @elixir-ts-font-sigil-name-face))
       @elixir-ts-font-string-regex-face
       (sigil
        "~" @elixir-ts-font-string-special-face
        (sigil_name) @elixir-ts-font-sigil-name-face
        quoted_start: _ @elixir-ts-font-string-special-face
        quoted_end: _ @elixir-ts-font-string-special-face
        (:match "^[HF]$" @elixir-ts-font-sigil-name-face)))

     :language 'elixir
     :feature 'elixir-string-escape
     :override t
     `((escape_sequence) @elixir-ts-font-string-escape-face)))
  "Tree-sitter font-lock settings.")

(defun elixir-ts-mode--forward-sexp (&optional arg)
  (interactive "^p")
  (or arg (setq arg 1))
  (funcall
   (if (> arg 0) #'treesit-end-of-thing #'treesit-beginning-of-thing)
   ;; do we exclude rather? most tokens we would like to match
   (if (eq (treesit-language-at (point)) 'heex)
       heex-ts-mode-sexp-regexp
     elixir-ts-mode-sexp-regexp)
   (abs arg)))

(defun elixir-ts-mode--treesit-anchor-grand-parent-bol (_n parent &rest _)
  "Return the beginning of non-space characters for the parent node of PARENT."
  (save-excursion
    (goto-char (treesit-node-start (treesit-node-parent parent)))
    (back-to-indentation)
    (point)))

(defvar elixir-ts-mode--treesit-range-rules
  (when (treesit-available-p)
    (treesit-range-rules
     :embed 'heex
     :host 'elixir
     '((sigil (sigil_name) @name (:match "^[HF]$" @name) (quoted_content) @heex)))))

(defun elixir-ts-mode--treesit-language-at-point (point)
  "Return the language at POINT."
  (let* ((range nil)
         (language-in-range
          (cl-loop
           for parser in (treesit-parser-list)
           do (setq range
                    (cl-loop
                     for range in (treesit-parser-included-ranges parser)
                     if (and (>= point (car range)) (<= point (cdr range)))
                     return parser))
           if range
           return (treesit-parser-language parser))))
    (if (null language-in-range)
        (when-let ((parser (car (treesit-parser-list))))
          (treesit-parser-language parser))
      language-in-range)))

(defun elixir-ts-mode--defun-p (node)
  "Return non-nil when NODE is a defun."
  (member (treesit-node-text
           (treesit-node-child-by-field-name node "target"))
          (append
           elixir-ts-mode--definition-keywords
           elixir-ts-mode--test-definition-keywords)))

(defun elixir-ts-mode--defun-name (node)
  "Return the name of the defun NODE.
Return nil if NODE is not a defun node or doesn't have a name."
  (pcase (treesit-node-type node)
    ("call" (let ((node-child
                   (treesit-node-child (treesit-node-child node 1) 0)))
              (pcase (treesit-node-type node-child)
                ("alias" (treesit-node-text node-child t))
                ("call" (treesit-node-text
                         (treesit-node-child-by-field-name node-child "target") t))
                ("binary_operator"
                 (treesit-node-text
                  (treesit-node-child-by-field-name
                   (treesit-node-child-by-field-name node-child "left") "target") t))
                ("identifier"
                 (treesit-node-text node-child t))
                (_ nil))))
    (_ nil)))

(defun elixir-ts-install-grammar ()
  "Experimental function to install the tree-sitter-elixir grammar."
  (interactive)
  (if (and (treesit-available-p) (boundp 'treesit-language-source-alist))
      (let ((treesit-language-source-alist
             (append
              treesit-language-source-alist
              elixir-ts-mode-default-grammar-sources)))
        (if (y-or-n-p
             (format
              (concat "The following language grammar repositories which will be "
                      "downloaded and installed "
                      "(%s %s), proceed?")
              (cadr (assoc 'elixir treesit-language-source-alist))
              (cadr (assoc 'heex treesit-language-source-alist))))
            (progn
              (treesit-install-language-grammar 'elixir)
              (treesit-install-language-grammar 'heex))))
    (display-warning
     'treesit
     (concat "Cannot install grammar because"
             " "
             "tree-sitter library is not compiled with Emacs"))))

(defun elixir-ts-mode-treesit-ready-p ()
  (let ((language-version 14))
    (and (treesit-ready-p 'elixir)
         (if (< (treesit-language-abi-version 'elixir) language-version)
             (progn
               (display-warning
                'treesit
                (format "Cannot activate tree-sitter for %s, because tree-sitter language version %s or later is required" "elixir-ts-mode" language-version))
               nil)
           t))))

;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("\\.elixir\\'" . elixir-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.ex\\'" . elixir-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.exs\\'" . elixir-ts-mode))
  (add-to-list 'auto-mode-alist '("mix\\.lock" . elixir-ts-mode)))

;;;###autoload
(define-derived-mode elixir-ts-mode prog-mode "Elixir"
  "Major mode for editing Elixir, powered by tree-sitter."
  :group 'elixir
  :syntax-table elixir-ts-mode--syntax-table

  ;; Comments
  (setq-local comment-start "# ")
  (setq-local comment-start-skip
              (rx "#" (* (syntax whitespace))))

  (setq-local comment-end "")
  (setq-local comment-end-skip
              (rx (* (syntax whitespace))
                  (group (or (syntax comment-end) "\n"))))

  ;; Compile
  (setq-local compile-command "mix")

  (when (elixir-ts-mode-treesit-ready-p)
    ;; heex has to be created first for elixir to be the first language
    ;; when looking for treesit ranges
    (when (heex-ts-mode-treesit-ready-p)
      (treesit-parser-create 'heex))

    (treesit-parser-create 'elixir)

    (setq-local treesit-font-lock-settings elixir-ts-mode--font-lock-settings)

    (setq-local forward-sexp-function #'elixir-ts-mode--forward-sexp)

    (setq-local treesit-simple-indent-rules
                (append elixir-ts-mode--indent-rules heex-ts-mode--indent-rules))

    (setq-local treesit-defun-name-function #'elixir-ts-mode--defun-name)

    ;; Imenu
    (setq-local treesit-simple-imenu-settings
                '((nil "\\`call\\'" elixir-ts-mode--defun-p nil)))

    ;; Navigation
    (setq-local treesit-defun-type-regexp
                '("call" . elixir-ts-mode--defun-p))

    (setq-local treesit-font-lock-feature-list
                '(( elixir-comment elixir-constant elixir-doc )
                  ( elixir-string elixir-keyword elixir-unary-operator
                    elixir-call elixir-operator )
                  ( elixir-sigil elixir-string-escape elixir-string-interpolation)))

    ;; Embedded Heex
    (when (treesit-ready-p 'heex)
      (treesit-parser-create 'heex)

      (setq-local treesit-language-at-point-function
                  'elixir-ts-mode--treesit-language-at-point)

      (setq-local treesit-range-settings elixir-ts-mode--treesit-range-rules)

      (setq-local treesit-font-lock-settings
                  (append treesit-font-lock-settings
                          heex-ts-mode--font-lock-settings))

      (setq-local treesit-simple-indent-rules
                  (append treesit-simple-indent-rules
                          heex-ts-mode--indent-rules))

      (setq-local treesit-font-lock-feature-list
                  '(( elixir-comment elixir-constant elixir-doc
                      heex-comment heex-keyword heex-doctype )
                    ( elixir-string elixir-keyword elixir-unary-operator
                      elixir-call elixir-operator
                      heex-component heex-tag heex-attribute heex-string)
                    ( elixir-sigil elixir-string-escape
                      elixir-string-interpolation ))))

    (treesit-major-mode-setup)))

(provide 'elixir-ts-mode)

;;; elixir-ts-mode.el ends here
