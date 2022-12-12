;;; move-mode.el --- A major-mode for editing Move language -*- lexical-binding: t; -*-

;; Copyright (c) 2022 Ashok Menon

;; Author: Ashok Menon
;; URL: https://github.com/amnn/move-mode
;; Package-Version: 20221205.1433
;; Package-Commit: fa34fbe977d62c8297abc3547b9cfb25802e033c
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1"))
;; Keywords: languages

;;; SPDX-License-Identifier: Apache-2.0

;;; Commentary:

;; This package implements a major-mode for editing smart contracts
;; written in Move.

;;; Code:



(require 'compile)

;;; Constants for use with Customization =================================== ;;;

(defconst move-core-builtin-functions
  '("assert!" "borrow_global" "freeze" "move_from" "move_to")
  "Built-in functions from Core Move.")

(defconst move-prover-keywords
  '("aborts_if" "aborts_with" "apply" "assume" "axiom" "choose" "decreases"
    "ensures" "emits" "except" "exists" "forall" "global" "include" "internal"
    "local" "min" "modifies" "old" "post" "pragma" "requires" "schema"
    "succeeds_if" "to" "update" "with" "where")
  "Keywords that are only used by the move prover.

Can be added to MOVE-BUILTINS to enable highlighting, defaults to not.")

;;; Customization ========================================================== ;;;

(defgroup move-lang nil
  "Support for Move source code."
  :link '(url-link "https://github.com/move-language/move")
  :group 'languages)

(defcustom move-indent-offset 4
  "Number of spaces to indent move code by."
  :type  'integer
  :group 'rust-mode
  :safe #'integerp)

(defcustom move-builtins move-core-builtin-functions
  "Functions to highlight as builtins (mutations require restarting font-lock)."
  :type '(list string)
  :group 'move-lang)

(defcustom move-bin "move"
  "Name of or path to move CLI binary."
  :type 'string
  :group 'move-lang)

(defcustom move-default-arguments ""
  "Default arguments when running common move CLI commands."
  :type 'string
  :group 'move-lang)

;;; Faces ================================================================== ;;;

(defface move-compilation-message-face
  '((t :inherit default))
  "`move-compilation-mode'-specific override of `compilation-message-face'.

Inherits from `default' face to avoid interfering with the ANSI colour filter."
  :group 'move-lang)

(defface move-compilation-error-face
  '((t :inherit default))
  "`move-compilation-mode'-specific override of `compilation-error-face'.

Inherits from `default' face to avoid interfering with the ANSI colour filter."
  :group 'move-lang)

(defface move-compilation-warning-face
  '((t :inherit default))
  "`move-compilation-mode'-specific override of `compilation-warning-face'.

Inherits from `default' face to avoid interfering with the ANSI colour filter."
  :group 'move-lang)

(defface move-compilation-line-face
  '((t :inherit default))
  "`move-compilation-mode'-specific override of `compilation-line-face'.

Inherits from `default' face to avoid interfering with the ANSI colour filter."
  :group 'move-lang)

(defface move-compilation-column-face
  '((t :inherit default))
  "`move-compilation-mode'-specific override of `compilation-column-face'.

Inherits from `default' face to avoid interfering with the ANSI colour filter."
  :group 'move-lang)

;;; Syntax ================================================================= ;;;

(defconst move-mode-syntax-table
  (let ((table (make-syntax-table)))

    ;; Operators
    (dolist (op '(?+ ?- ?* ?/ ?% ?& ?^ ?| ?< ?> ?! ?&))
      (modify-syntax-entry op "." table))

    ;; Parentheses
    (modify-syntax-entry ?\(  "()" table)
    (modify-syntax-entry ?\)  ")(" table)
    (modify-syntax-entry ?\{  "(}" table)
    (modify-syntax-entry ?\}  "){" table)
    (modify-syntax-entry ?\[  "(]" table)
    (modify-syntax-entry ?\]  ")[" table)

    ;; Comments
    (modify-syntax-entry ?/   ". 124b" table)
    (modify-syntax-entry ?*   ". 23n"  table)
    (modify-syntax-entry ?\n  "> b"    table)
    (modify-syntax-entry ?\^m "> b"    table)

    table))

(defconst move-mode-syntax-table+<>
  (let ((table (copy-syntax-table move-mode-syntax-table)))
    (modify-syntax-entry ?< "(>" table)
    (modify-syntax-entry ?> ")<" table)

    table)
  "Variant of syntax table recognising angle braces as bracketed.

For use in detecting generic paramters.")

;;; Keybindings ============================================================ ;;;

(defvar move-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c C-b") #'move-build)
    (define-key map (kbd "C-c C-c C-d") #'move-disassemble)
    (define-key map (kbd "C-c C-c C-p") #'move-prover)
    (define-key map (kbd "C-c C-c C-t") #'move-test)
    map))

;;; Compilation ============================================================ ;;;

(defvar move-error-pattern
  (let* ((err  "error\\[E[0-9]+\\]:\s[^\n]+")
         (box  "\s*\\(?:\u2502\s+\\)*\u250c\u2500\s")
         (file "\\([^\n]+\\)")
         (line "\\([0-9]+\\)")
         (col  "\\([0-9]+\\)")
         (patt (concat err "\n" box file ":" line ":" col)))
    (list patt #'move--expand-compilation-source 2 3 0))
  "Link to sources for compilation errors.")

(defvar move-warning-pattern
  (let* ((warn "warning\\[W[0-9]+\\]:\s[^\n]+")
         (box  "\s*\\(?:\u2502\s+\\)*\u250c\u2500\s")
         (file "\\([^\n]+\\)")
         (line "\\([0-9]+\\)")
         (col  "\\([0-9]+\\)")
         (patt (concat warn "\n" box file ":" line ":" col)))
    (list patt #'move--expand-compilation-source 2 3 1))
  "Link to sources for compilation warnings.")

;;; Modes ================================================================== ;;;

;;;###autoload
(define-derived-mode move-mode prog-mode "Move"
  "Major mode for Move source code.

\\{move-mode-map}"
  :group 'move-lang
  :syntax-table move-mode-syntax-table

  (setq-local font-lock-defaults
              '(move-mode-font-lock-keywords
                nil ;; KEYWORDS-ONLY
                nil ;; CASE-FOLD
                nil ;; SYNTAX-ALIST
                ;;;;;; VARIABLES
                (font-lock-syntactic-face-function
                 . move-mode-distinguish-comments)))

  ;; ! is punctuation unless it's at the end of a word, in which case,
  ;; it should be treated like piece of the preceding word.
  (setq-local syntax-propertize-function
              (syntax-propertize-rules ("\\sw\\(!\\)" (1 "w"))))

  ;; This is a weirdly lisp-specific variable
  (setq-local open-paren-in-column-0-is-defun-start nil)

  ;; Indentation
  (setq-local indent-line-function #'move-mode-indent-line)
  (setq-local electric-indent-chars
              (cons ?} (and (boundp 'electric-indent-chars)
                            electric-indent-chars)))

  ;; Comments
  (setq-local comment-end        "")
  (setq-local comment-line-break-function #'move-mode-comment-line-break)
  (setq-local comment-multi-line t)
  (setq-local comment-start      "// ")
  (setq-local comment-start-skip "\\(?://[/!]*\\|/\\*[*!]?\\)\\s-*")

  ;; Set paragraph-start to stop multi-line comments creeping up onto
  ;; an empty initial line, or across lines that contain only a `*'
  ;; and are therefore effectively empty.
  (setq-local paragraph-start
              (concat "\\s-*\\(?:" comment-start-skip ;; Comment start
                      "\\|\\*/?[[:space:]]*"          ;; Empty line in a comment
                      "\\|\\)$"))                     ;; Just plain empty
  (setq-local paragraph-separate
              paragraph-start)

  ;; Fill Paragraph
  (setq-local fill-paragraph-function   #'move-mode-fill-paragraph)
  (setq-local normal-auto-fill-function #'move-mode-auto-fill)
  (setq-local adaptive-fill-function    #'move-mode-adaptive-fill)
  (setq-local adaptive-fill-first-line-regexp ""))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.move\\'" . move-mode))

(define-compilation-mode move-compilation-mode "move-compilation"
  "Move compilation mode.

Defines regexps for matching file names in compiler output, replacing defaults."
  (setq-local compilation-error-regexp-alist-alist nil)
  (add-to-list 'compilation-error-regexp-alist-alist
               (cons 'move-error move-error-pattern))
  (add-to-list 'compilation-error-regexp-alist-alist
               (cons 'move-warning move-warning-pattern))

  (setq-local compilation-error-regexp-alist nil)
  (add-to-list 'compilation-error-regexp-alist 'move-error)
  (add-to-list 'compilation-error-regexp-alist 'move-warning)

  (setq-local compilation-message-face 'move-compilation-message-face)
  (setq-local compilation-error-face   'move-compilation-error-face)
  (setq-local compilation-warning-face 'move-compilation-warning-face)
  (setq-local compilation-column-face  'move-compilation-column-face)
  (setq-local compilation-line-face    'move-compilation-line-face)

  (add-hook 'compilation-filter-hook
            #'move--ansi-color-compilation-filter nil t))

;;; Font Lock ============================================================== ;;;

(defconst move-keywords
  '("abort" "acquires" "as" "break" "const" "continue" "copy" "else" "entry"
    "false" "friend" "fun" "has" "if" "invariant" "let" "loop" "module" "move"
    "mut" "native" "public" "return" "script" "spec" "struct" "true" "use"
    "while"))

(defconst move-integer-types
  '("u8" "u16" "u32" "u64" "u128" "u256"))

(defconst move-builtin-types
  (append move-integer-types '("address" "bool" "vector")))

(defconst move-abilities
  '("copy" "drop" "store" "key"))

(defconst move-integer-with-type-re
  (concat "\\_<"
          "\\(?:0x?\\|[1-9]\\)"
          "[[:digit:]a-fA-F]*"
          (regexp-opt move-integer-types t)
          "\\_>"))

(defconst move-ident-re
  "[a-zA-Z][a-zA-Z0-9_]*\\|_[a-zA-Z0-9_]+")

(defconst move-type-re
  "\\_<[A-Z][a-zA-Z0-9_]*\\_>")

(defconst move-limit-by-<>-form
  '(if (not (char-equal ?< (char-after))) (point)
       (with-syntax-table move-mode-syntax-table+<>
         (save-excursion (forward-sexp) (point))))
  "Returns position one after a matching closed angle bracket.

When the form is evaluaed with the point over an open angled bracket.")

(defconst move-generic-constraint-matcher
  `(,(regexp-opt move-abilities 'symbols)
    ,move-limit-by-<>-form nil
    (0 font-lock-type-face))
  "Font lock sub-matcher for type constraints on generic type parameters.

Generic type parameters are enclosed by type parameters.")

(defvar move-mode-font-lock-keywords
  `((,(regexp-opt move-keywords 'symbols)      . font-lock-keyword-face)
    (,(regexp-opt move-builtin-types 'symbols) . font-lock-type-face)
    ("\\(#\\[[^]]*\\]\\)"                      1 font-lock-preprocessor-face keep)
    (,move-integer-with-type-re                1 font-lock-type-face)

    ;; "Types" heuristic -- CapitalizedIdentifiers.
    (,move-type-re                             . font-lock-type-face)

    ;; Module components
    (,(concat "\\(" move-ident-re "\\)::")     1 font-lock-constant-face)

    ;; Fields, function params, local variables with explicit types
    (,(concat "\\(" move-ident-re "\\)\\s-*:[^:]")
     1 font-lock-variable-name-face)

    ;; Let bindings with inferred type
    (,(concat "\\_<let\\s-+\\(" move-ident-re "\\)\\_>")
     1 font-lock-variable-name-face)

    ;; Function declarations
    (,(concat "\\_<fun\\s-+\\(" move-ident-re "\\)\\s-*")
     (1 font-lock-function-name-face)
     ,move-generic-constraint-matcher)

    ;; Struct declarations
    (,(concat "\\_<struct\\s-+\\(" move-ident-re "\\)\\s-*")
     (1 font-lock-type-face)

     ("\\_<phantom\\_>"
      ,move-limit-by-<>-form
      (with-syntax-table move-mode-syntax-table+<>
        (up-list) (backward-list))
      (0 font-lock-keyword-face))

     ,move-generic-constraint-matcher)

    ("\\_<has\\_>"

     (,(regexp-opt move-abilities 'symbols)
      (save-excursion
        (re-search-forward "{" (point-at-eol) t +1)
        (point))

      nil

      (0 font-lock-type-face)))

    (eval move--register-builtins)))

;;; Interactive Functions ================================================== ;;;

(defun move-build ()
  "Run `move build', returning output in a compilation buffer.

`move' refers to the move binary, which is customizable at `move-bin'."
  (interactive)
  (move--compilation-start "build"))

(defun move-prover ()
  "Run `move prover', returning output in a compilation buffer.

`move' refers to the move binary, which is customizable at `move-bin'."
  (interactive)
  (move--compilation-start "prover"))

(defun move-test ()
  "Run `move test', returning output in a compilation buffer.

`move' refers to the move binary, which is customizable at `move-bin'."
  (interactive)
  (move--compilation-start "test"))

(defun move-disassemble (module-name)
  "Disassemble MODULE-NAME, returning the output in a compilation buffer.

Uses the `disassemble' subcommand, passing MODULE-NAME with its `--name'
argument.  `move' refers to the move binary, which is customizable at
`move-bin'."
  (interactive "sModule: ")
  (move--compilation-start "disassemble" "--name" module-name))

(defun move-mode-indent-line ()
  "Set the indent of the current line.

The column is calculated by MOVE--INDENT-COLUMN.  Jump to that column if the
point is currently before it, leave the point in place otherwise."
  (interactive)
  (let ((indent (move--indent-column)))
    (when indent
      (if (<= (current-column) (current-indentation))
          (indent-line-to indent)
        (save-excursion
          (indent-line-to indent))))))

;;; Comments and Fill ====================================================== ;;;

(defun move-mode-distinguish-comments (state)
  "Distinguish between doc comments and normal comments in syntax STATE."
  (save-excursion
    (goto-char (nth 8 state))
    (cond ((looking-at "//[/!][^/!]")
           'font-lock-doc-face)
          ((looking-at "/[*][*!][^*!]")
           'font-lock-doc-face)
          ('font-lock-comment-face))))

(defun move-mode-comment-line-break (&optional soft)
  "Create a new line continuing the comment at point.

SOFT is forwarded to `comment-indent-new-line'."
  (let ((fill-prefix (move-mode-adaptive-fill)))
    (comment-indent-new-line soft)))

(defun move-mode-fill-paragraph (&rest args)
  "Move comment-aware wrapper for `fill-paragraph'.

ARGS are forwarded to a call of `fill-paragraph', as-is."
  (let ((fill-prefix (move-mode-adaptive-fill))
        (fill-paragraph-handle-comment t)
        (fill-paragraph-function
         (unless (eq fill-paragraph-function #'move-mode-fill-paragraph)
           fill-paragraph-function)))
    (apply #'fill-paragraph args) t))

(defun move-mode-auto-fill (&rest args)
  "Move comment-aware wrapper for `do-auto-fill'.

ARGS are forwarded to a call of `do-auto-fill', as-is."
  (let ((fill-prefix (move-mode-adaptive-fill)))
    (apply #'do-auto-fill args) t))

(defun move-mode-adaptive-fill ()
  "Pick the `fill-prefix' based on context.

If the point is currently in a comment, return the fill prefix to us to continue
that comment, otherwise return the existing `fill-prefix'."
  (save-match-data
    (save-excursion
      (if (not (move--ppss-in-comment))
          fill-prefix
        (let* ((comment-start
                (move--ppss-comment-start))
               (comment-indent
                (progn (goto-char comment-start)
                       (beginning-of-line)
                       (buffer-substring-no-properties
                        (point) comment-start))))
          (goto-char comment-start)
          (cond
           ((looking-at "//[/!]*\\s-*")
            (concat comment-indent (match-string-no-properties 0)))
           ((looking-at "/\\*[*!]?\\s-*")
            (concat comment-indent " * "))
           (t fill-prefix)))))))

;;; Private Helper Functions =============================================== ;;;

(defun move--expand-compilation-source ()
  "Resolve compiler error/warning files relative to `compilation-directory'."
  (expand-file-name (match-string-no-properties 1) compilation-directory))

(defun move--compilation-start (sub-command &rest args)
  "Run a `move' sub-command from the Move project root.

Invokes `move-bin' with `move-default-arguments' SUB-COMMAND, and ARGS."
  (let* ((compilation-directory
          (locate-dominating-file default-directory "Move.toml")))
    (compilation-start
     (combine-and-quote-strings
      (append (list move-bin sub-command)
              (split-string-and-unquote move-default-arguments)
              args))
     'move-compilation-mode)))

(defun move--register-builtins ()
  "Generate a font-lock matcher form for built-in constructs.

The list of built-ins is specified via the `move-builtins' custom variable."
  `(,(regexp-opt move-builtins 'symbols) . font-lock-builtin-face))

(defun move--ppss-inner-paren ()
  "Character address of innermost containing list, or nil if none."
  (nth 1 (syntax-ppss)))

(defun move--ppss-in-comment ()
  "Whether or not the cursor is within a comment.

NIL if outside a comment, T if inside a non-nestable comment, or an integer --
the level of nesting -- if inside a nestable comment."
  (nth 4 (syntax-ppss)))

(defun move--ppss-comment-start ()
  "Character address for start of comment or string."
  (nth 8 (syntax-ppss)))

(defun move--prev-assignment (bound)
  "Find the previous assignment character after BOUND.

Search backwards from the current point until BOUND looking for an `='
character that isn't in a comment.  Returns T on success, with the point over
the character, and NIL otherwise with the point at an indeterminate position."
  (and (search-backward "=" bound t)
       (or (not (move--ppss-in-comment))
           (move--prev-assignment bound))))

(defun move--next-terminator (bound)
  "Find the next statement terminator before BOUND.

Search forwards from the current point until BOUND looking for a `;' character
that isn't in a comment.  Returns T on success, with the point over the
character, and NIL otherwise with the point at an indeterminate position."
  (and (search-forward ";" bound t)
       (or (not (move--ppss-in-comment))
           (move--next-terminator bound))))

(defun move--indent-column ()
  "Calculates the column to indent the current line to.

The default indent is `move-indent-offset' greater than the indent of the line
containing the innermost parenthesis at point, or 0 if there is no such
innermost paren.

This column is modified for closing parens, which are dedented by the offset,
continuation lines of `/*'-style comments, which are indented by 1 to line up
their `*', and assignment continuation lines, which are indented by a further
offset."
  (save-excursion
    (back-to-indentation)
    (let* ((current-posn   (point))
           (parent-paren   (move--ppss-inner-paren))
           (default-indent (if (not parent-paren) 0
                             (save-excursion
                               (goto-char parent-paren)
                               (back-to-indentation)
                               (+ (current-column) move-indent-offset)))))
      (cond
       ;; `/*'-style comment continuation lines
       ((and (move--ppss-in-comment)
             (looking-at "*"))
        (+ default-indent 1))

       ;; Top-level items will remain completely unindented.
       ((= default-indent 0) 0)

       ;; Closing parentheses
       ((looking-at "[]})]")
        (- default-indent move-indent-offset))

       ;; Assignment continuation lines
       ((save-excursion
          (and parent-paren
               (save-excursion (goto-char parent-paren)
                               (looking-at "{"))
               (move--prev-assignment parent-paren)
               (not (move--next-terminator current-posn))))
        (+ default-indent move-indent-offset))

       (t default-indent)))))

(defun move--ansi-color-compilation-filter ()
  "Backport ANSI color compilation filter to support earlier versions of Emacs."
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region compilation-filter-start (point))))

(provide 'move-mode)

;;; move-mode.el ends here
