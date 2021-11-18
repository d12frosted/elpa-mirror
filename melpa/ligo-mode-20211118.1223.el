;;; ligo-mode.el --- A major mode for editing LIGO source code

;; Version: 0.1.0
;; Package-Version: 20211118.1223
;; Package-Commit: eaf7d8d8f65e90f9cf35ddff440b14e9513449e5
;; Author: LigoLang SASU
;; Url: https://gitlab.com/ligolang/ligo/-/tree/dev/tools/emacs
;; Keywords: languages
;; Package-Requires: ((emacs "27.1"))

;; This file is distributed under the terms of the MIT license.

;;; Commentary:

;; This provides font lock and other support for the three dialects of
;; the Ligo smart contract language for the Tezos blockchain.

;; For users of `lsp-mode', setup can be performed automatically by
;; calling the command `ligo-setup-lsp', or with the following snippet
;; in an init file:

;;   (with-eval-after-load 'lsp-mode
;;     (with-eval-after-load 'ligo-mode
;;       (ligo-setup-lsp)))

;;; Code:

(eval-when-compile
  (require 'rx))
(require 'subr-x)

;; ------------------------------------------------
;;             Customizable options
;; ------------------------------------------------

(defgroup ligo nil
  "Support for LIGO code."
  :link '(url-link "https://www.ligolang.org/")
  :group 'languages)

(defcustom ligo-squirrel-bin "ligo-squirrel"
  "Path to LIGO language server executable."
  :type 'string
  :group 'ligo)

(defface ligo-constructor-face
  '((t :inherit font-lock-type-face))
  "Face for value constructors."
  :group 'ligo)

;; ------------------------------------------------
;;     Common variables, regexes and functions
;; ------------------------------------------------

(rx-define ligo-ident-symbol (or (syntax word) (syntax symbol)))
(rx-define ligo-ident (1+ ligo-ident-symbol))
(rx-define ligo-lower-ident (: symbol-start (or "_" lower) (0+ ligo-ident-symbol)))
(rx-define ligo-upper-ident (: symbol-start upper (0+ ligo-ident-symbol)))

(rx-define ligo-macro
  (: "#" (or "define" "undef" "if" "else" "elif" "endif" "include" "import" "error")))

(rx-define ligo-macro-expr
  (: (group ligo-macro) (group (* any)) eol))

(rx-define ligo-upper-qname
  (: (group ligo-upper-ident) (1+ (: "." (group ligo-lower-ident)))))

(rx-define ligo-typedef
  (: symbol-start (group "type") symbol-end (* space)
     (group ligo-lower-ident)))

(rx-define ligo-common-constants
  ; numbers: 0n, 5mutez, 0x100
  (: (1+ digit) (0+ ligo-ident-symbol) (0+ digit)))

(defun ligo--type-end (type-end-re limit)
  "Finds the end of a type annotation"
  (catch 'ligo-type-end
    (while t
      (let* ((regex-with-parens (rx (or (group "(") ")" (regexp type-end-re) )))  ; "(" is treated specially
             (match (re-search-forward regex-with-parens limit t)))
        (cond
         ;; Couldn't find any end matches within the limit
         ((null match) (throw 'ligo-type-end nil))
         ;; Reached the end of the type definition, returning the start pos of the match
         ((null (match-string 1)) (throw 'ligo-type-end (car (match-data))))
         ;; Found an open paren, find the balanced pair and continue
         (t
          (catch 'scan-error
            (goto-char (scan-lists (point) 1 1)))))))))

(defun ligo-type-matcher (type-start-matcher type-end-re)
  "Matches type annotations that possibly include braces"
  `(lambda (limit)
    (unless (null (,type-start-matcher limit))
      (let* ((colon-group (match-data))
             (begin (nth 1 colon-group))
             (end (ligo--type-end ,type-end-re limit)))
        (unless (null end)
          (progn
            (set-match-data (list begin end))
            t))))))

(defun ligo-colon-matcher (limit)
  "Finds the char before the first colon"
  ;; We need to handle hd::tail notation, so we can't just match ':'
  ;; elisp doesn't support negative lookaheads, so we have to
  ;; match [^:]:[^:] and then update the match data, which is
  ;; an ugly but working solution
  (when-let* ((colon (re-search-forward (rx (not ":") ":" (not ":")) limit t)))
    (let ((colon-match-begin (car (match-data)))
          (colon-match-end (nth 1 (match-data))))
      (backward-char)
      (set-match-data
        `(,(set-marker colon-match-begin (+ colon-match-begin 1))
          ,(set-marker colon-match-end (- colon-match-end 1))))
      (- colon 1))))

(defun ligo-colon () (interactive) (ligo-colon-matcher nil))

(defun ligo-syntax-table ()
  "Common syntax table for all LIGO dialects."
  (let ((st (make-syntax-table)))
    ;; Identifiers
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?' "_" st)
    (modify-syntax-entry ?. "'" st)

    ;; Punctuation
    (dolist (c '(?# ?! ?$ ?% ?& ?+ ?- ?/ ?: ?< ?= ?> ?@ ?^ ?| ?? ?~))
      (modify-syntax-entry c "." st))

    ;; Quotes
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\\ "\\" st)

    ;; Comments are different in dialects, so they should be added
    ;; by dialect-specific syntax tables
    st))


;; ------------------------------------------------
;;     PascaLIGO-specific variables and regexes
;; ------------------------------------------------

(rx-define ligo-pascal-type-end
  (or "," ";" "=" ":=" (: symbol-start "is" symbol-end) eol))

(rx-define ligo-pascal-variable-def
  (: symbol-start (group (or "const" "var")) symbol-end (* space)
     (group ligo-lower-ident)))

(rx-define ligo-pascal-function-def
  (: symbol-start (group "function") symbol-end (* space)
     (group ligo-lower-ident)))

(rx-define ligo-pascal-constant
  (or ligo-common-constants
      (: symbol-start "true" symbol-end)
      (: symbol-start "false" symbol-end)))

(defvar ligo-pascal-keywords
  '("type" "in" "is" "for" "block" "begin" "end" "failwith" "assert" "with"
    "record" "of" "function" "var" "const" "if" "then" "else" "case"))

(defvar ligo-pascal-builtins
  '("list"))

(defvar ligo-pascal-mode-highlights
  `(;; Preprocessor macros
    (,(rx ligo-macro-expr)
     . ((1 font-lock-preprocessor-face) (2 font-lock-string-face)))

    ;; Type definitions ("type foo")
    (,(rx ligo-typedef)
     . ((1 font-lock-keyword-face) (2 font-lock-type-face)))

    ;; Variable definitions ("const x", "var y")
    (,(rx ligo-pascal-variable-def)
     . ((1 font-lock-keyword-face) (2 font-lock-variable-name-face)))

    ;; Function definitions ("function bar")
    (,(rx ligo-pascal-function-def)
     . ((1 font-lock-keyword-face) (2 font-lock-function-name-face)))

    ;; Keywords
    (,(regexp-opt ligo-pascal-keywords 'symbols) . font-lock-keyword-face)

    ;; Big_map.remove, Tezos.address
    (,(rx ligo-upper-qname)
     . ((1 font-lock-builtin-face)))

    ;; ": type" annotations
    (,(ligo-type-matcher 'ligo-colon-matcher (rx ligo-pascal-type-end))
     . font-lock-type-face)
    
    ;; Unqualified builtin functions like "list" in PascaLIGO
    (,(regexp-opt ligo-pascal-builtins 'symbols) . font-lock-builtin-face)
    
    ;; Constructors
    (,(rx ligo-upper-ident) . 'ligo-constructor-face)

    ;; Constants: True, False, 0n, 5mutez
    (,(rx ligo-pascal-constant) . font-lock-constant-face))
  "Syntax highlighting rules for PascaLIGO.")

(defun ligo-pascal-mode-syntax-table ()
  "PascaLIGO syntax table."
  (let ((st (ligo-syntax-table)))
    ; Caml & Pascal style comments
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?/  ". 12b" st)
    (modify-syntax-entry ?*  ". 23" st)
    (modify-syntax-entry ?\( "()1n" st)
    (modify-syntax-entry ?\) ")(4n" st)
    st))

;; ------------------------------------------------
;;                   Exports
;; ------------------------------------------------

(defun ligo-reload ()
  "Reload the ligo-mode code and re-apply the default major mode in the current buffer."
  (interactive)
  (unload-feature 'ligo-mode)
  (require 'ligo-mode)
  (normal-mode))

;;;###autoload
(define-derived-mode ligo-pascal-mode prog-mode "ligo"
  "Major mode for writing PascaLIGO code."
  (setq font-lock-defaults '(ligo-pascal-mode-highlights))
  (set-syntax-table (ligo-pascal-mode-syntax-table)))

;; Forward declarations for byte compiler
(defvar lsp-language-id-configuration)
(declare-function lsp-register-client 'lsp-mode)
(declare-function make-lsp-client 'lsp-mode)
(declare-function lsp-stdio-connection 'lsp-mode)

;;;###autoload
(defun ligo-setup-lsp ()
  "Set up an LSP backend for ligo that will use `ligo-squirrel-bin'."
  (interactive)
  (add-to-list 'lsp-language-id-configuration '(ligo-pascal-mode . "ligo"))
  (add-to-list 'lsp-language-id-configuration '(ligo-caml-mode . "ligo"))
  (add-to-list 'lsp-language-id-configuration '(ligo-reason-mode . "ligo"))
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection `(,ligo-squirrel-bin))
    :major-modes '(ligo-pascal-mode ligo-caml-mode ligo-reason-mode)
    :server-id 'ligo)))

;;;###autoload
(define-obsolete-function-alias 'ligo-mode 'normal-mode "2021-02")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ligo\\'" . ligo-pascal-mode))

(provide 'ligo-mode)
;;; ligo-mode.el ends here

;; copy pasted ligo-caml-mode
(defface ligo-font-lock-attribute-face
	'(
		(t (:inherit font-lock-preprocessor-face ))
	)
	"Face description for todos."
	:group 'ligo
)
(defvar ligo-font-lock-attribute-face
	'ligo-font-lock-attribute-face)

(defface ligo-font-lock-character-face
	'(
		(t (:inherit font-lock-string-face ))
	)
	"Face description for characters."
	:group 'ligo
)
(defvar ligo-font-lock-character-face
	'ligo-font-lock-character-face)

(defface ligo-font-lock-number-face
	'(
		(t (:inherit default ))
	)
	"Face description for numbers."
	:group 'ligo
)
(defvar ligo-font-lock-number-face
	'ligo-font-lock-number-face)

(defface ligo-font-lock-float-face
	'(
		(t (:inherit default ))
	)
	"Face description for floats."
	:group 'ligo
)
(defvar ligo-font-lock-float-face
	'ligo-font-lock-float-face)

(defface ligo-font-lock-builtin-function-face
	'(
		(t (:inherit font-lock-function-name-face ))
	)
	"Face description for builtin functions."
	:group 'ligo
)
(defvar ligo-font-lock-builtin-function-face
	'ligo-font-lock-builtin-function-face)

(defface ligo-font-lock-statement-face
	'(
		(t (:inherit font-lock-keyword-face ))
	)
	"Face description for statements."
	:group 'ligo
)
(defvar ligo-font-lock-statement-face
	'ligo-font-lock-statement-face)

(defface ligo-font-lock-conditional-face
	'(
		(t (:inherit font-lock-keyword-face ))
	)
	"Face description for conditionals."
	:group 'ligo
)
(defvar ligo-font-lock-conditional-face
	'ligo-font-lock-conditional-face)

(defface ligo-font-lock-repeat-face
	'(
		(t (:inherit font-lock-keyword-face ))
	)
	"Face description for repeat keywords."
	:group 'ligo
)
(defvar ligo-font-lock-repeat-face
	'ligo-font-lock-repeat-face)

(defface ligo-font-lock-label-face
	'(
		(((background dark)) (:foreground "#eedd82" ))
		(t (:inherit font-lock-function-name-face ))
	)
	"Face description for labels."
	:group 'ligo
)
(defvar ligo-font-lock-label-face
	'ligo-font-lock-label-face)

(defface ligo-font-lock-operator-face
	'(
		(t (:inherit default ))
	)
	"Face description for operators."
	:group 'ligo
)
(defvar ligo-font-lock-operator-face
	'ligo-font-lock-operator-face)

(defface ligo-font-lock-exception-face
	'(
		(((background light)) (:foreground "dark orange" ))
		(((background dark)) (:foreground "orange" ))
	)
	"Face description for exceptions."
	:group 'ligo
)
(defvar ligo-font-lock-exception-face
	'ligo-font-lock-exception-face)

(defface ligo-font-lock-builtin-type-face
	'(
		(t (:inherit font-lock-type-face ))
	)
	"Face description for builtin types."
	:group 'ligo
)
(defvar ligo-font-lock-builtin-type-face
	'ligo-font-lock-builtin-type-face)

(defface ligo-font-lock-storage-class-face
	'(
		(t (:inherit font-lock-keyword-face ))
	)
	"Face description for storage classes."
	:group 'ligo
)
(defvar ligo-font-lock-storage-class-face
	'ligo-font-lock-storage-class-face)

(defface ligo-font-lock-builtin-module-face
	'(
		(t (:inherit font-lock-function-name-face ))
	)
	"Face description for builtin modules."
	:group 'ligo
)
(defvar ligo-font-lock-builtin-module-face
	'ligo-font-lock-builtin-module-face)

(defface ligo-font-lock-structure-face
	'(
		(t (:inherit font-lock-constant-face ))
	)
	"Face description for structures."
	:group 'ligo
)
(defvar ligo-font-lock-structure-face
	'ligo-font-lock-structure-face)

(defface ligo-font-lock-type-def-face
	'(
		(t (:inherit font-lock-type-face ))
	)
	"Face description for type definitions."
	:group 'ligo
)
(defvar ligo-font-lock-type-def-face
	'ligo-font-lock-type-def-face)

(defface ligo-font-lock-special-char-face
	'(
		(t (:inherit font-lock-string-face ))
	)
	"Face description for special characters."
	:group 'ligo
)
(defvar ligo-font-lock-special-char-face
	'ligo-font-lock-special-char-face)

(defface ligo-font-lock-special-comment-face
	'(
		(t (:inherit font-lock-comment-face ))
	)
	"Face description for special comments."
	:group 'ligo
)
(defvar ligo-font-lock-special-comment-face
	'ligo-font-lock-special-comment-face)

(defface ligo-font-lock-error-face
	'(
		(t (:inherit error ))
	)
	"Face description for errors."
	:group 'ligo
)
(defvar ligo-font-lock-error-face
	'ligo-font-lock-error-face)

(defface ligo-font-lock-todo-face
	'(
		(t (:inherit highlight ))
	)
	"Face description for todos."
	:group 'ligo
)
(defvar ligo-font-lock-todo-face
	'ligo-font-lock-todo-face)

(defun mligo-syntax-table ()
	"Syntax table"
	(let ((st (make-syntax-table)))
	(modify-syntax-entry ?_ "w" st)
	(modify-syntax-entry ?' "_" st)
	(modify-syntax-entry ?. "'" st)
	(modify-syntax-entry ?^ "." st)
	(modify-syntax-entry ?# "." st)
	(modify-syntax-entry ?< "." st)
	(modify-syntax-entry ?> "." st)
	(modify-syntax-entry ?/ "." st)
	(modify-syntax-entry ?* "." st)
	(modify-syntax-entry ?- "." st)
	(modify-syntax-entry ?+ "." st)
	(modify-syntax-entry ?\" "\"" st)
	(modify-syntax-entry ?
 "> b" st)
	(modify-syntax-entry ?/ ". 12b" st)
	(modify-syntax-entry ?* ". 23" st)
	(modify-syntax-entry ?\( "()1n" st)
	(modify-syntax-entry ?\) ")(4n" st)
	st))

(defvar mligo-font-lock-defaults
	`(
		(,"\\[@.*\\]"
			. ligo-font-lock-attribute-face
		)
		(,"^\\(#[a-zA-Z]+\\)"
			. font-lock-preprocessor-face
		)
		(,"\\b\\(match\\|with\\|if\\|then\\|else\\|assert\\|failwith\\|begin\\|end\\|in\\)\\b"
			. ligo-font-lock-conditional-face
		)
		(,"\\b\\(let\\)\\b[ ]*\\b\\(rec\\|\\)\\b[ ]*\\b\\([a-zA-Z$_][a-zA-Z0-9$_]*\\|\\)"
			(1 font-lock-keyword-face)
			(2 ligo-font-lock-storage-class-face)
			(3 font-lock-function-name-face)
		)
		(,"\\b[-+]?\\([0-9]+\\)\\(n\\|\\tz\\|tez\\|mutez\\|\\)\\b"
			. ligo-font-lock-number-face
		)
		(,"[ ]*\\(::\\|-\\|+\\|/\\|mod\\|land\\|lor\\|lxor\\|lsl\\|lsr\\|&&\\|||\\|<\\|>\\|<>\\|<=\\|>=\\)[ ]*"
			. ligo-font-lock-operator-face
		)
		(,"\\(:[ ]*[^]=;\\):]*\\)"
			. font-lock-type-face
		)
		(,"\\(*\\)"
			. ligo-font-lock-operator-face
		)
		(,"\\b\\(fun\\)\\b" ( 1 ligo-font-lock-statement-face))
		(,"\\b\\(type\\)\\b"
			. font-lock-type-face
		)
		(,"\\b\\([A-Z][a-zA-Z0-9_$]*\\)\\.\\([a-z_][a-zA-Z0-9_$]*\\)\\b"
			(1 ligo-font-lock-structure-face)
			(2 font-lock-variable-name-face)
		)
		(,"\\b\\([A-Z][a-zA-Z0-9_$]*\\)\\b"
			(1 ligo-font-lock-label-face)
		)
	)
	"Syntax highlighting rules for mligo")
(defun mligo-reload ()
	"Reload the mligo-mode code and re-apply the default major mode in the current buffer."
	(interactive)
	(unload-feature 'mligo-mode)
	(require 'mligo-mode)
	(normal-mode))

(define-derived-mode ligo-caml-mode prog-mode "mligo"
	"Major mode for writing mligo code."
	(setq font-lock-defaults '(mligo-font-lock-defaults))
	(set-syntax-table (mligo-syntax-table)))

(add-to-list 'auto-mode-alist '("\\.mligo\\'" . ligo-caml-mode))
(provide 'mligo-mode)

(defface ligo-font-lock-attribute-face
	'(
		(t (:inherit font-lock-preprocessor-face ))
	)
	"Face description for todos."
	:group 'ligo
)
(defvar ligo-font-lock-attribute-face
	'ligo-font-lock-attribute-face)

(defface ligo-font-lock-character-face
	'(
		(t (:inherit font-lock-string-face ))
	)
	"Face description for characters."
	:group 'ligo
)
(defvar ligo-font-lock-character-face
	'ligo-font-lock-character-face)

(defface ligo-font-lock-number-face
	'(
		(t (:inherit default ))
	)
	"Face description for numbers."
	:group 'ligo
)
(defvar ligo-font-lock-number-face
	'ligo-font-lock-number-face)

(defface ligo-font-lock-float-face
	'(
		(t (:inherit default ))
	)
	"Face description for floats."
	:group 'ligo
)
(defvar ligo-font-lock-float-face
	'ligo-font-lock-float-face)

(defface ligo-font-lock-builtin-function-face
	'(
		(t (:inherit font-lock-function-name-face ))
	)
	"Face description for builtin functions."
	:group 'ligo
)
(defvar ligo-font-lock-builtin-function-face
	'ligo-font-lock-builtin-function-face)

(defface ligo-font-lock-statement-face
	'(
		(t (:inherit font-lock-keyword-face ))
	)
	"Face description for statements."
	:group 'ligo
)
(defvar ligo-font-lock-statement-face
	'ligo-font-lock-statement-face)

(defface ligo-font-lock-conditional-face
	'(
		(t (:inherit font-lock-keyword-face ))
	)
	"Face description for conditionals."
	:group 'ligo
)
(defvar ligo-font-lock-conditional-face
	'ligo-font-lock-conditional-face)

(defface ligo-font-lock-repeat-face
	'(
		(t (:inherit font-lock-keyword-face ))
	)
	"Face description for repeat keywords."
	:group 'ligo
)
(defvar ligo-font-lock-repeat-face
	'ligo-font-lock-repeat-face)

(defface ligo-font-lock-label-face
	'(
		(((background dark)) (:foreground "#eedd82" ))
		(t (:inherit font-lock-function-name-face ))
	)
	"Face description for labels."
	:group 'ligo
)
(defvar ligo-font-lock-label-face
	'ligo-font-lock-label-face)

(defface ligo-font-lock-operator-face
	'(
		(t (:inherit default ))
	)
	"Face description for operators."
	:group 'ligo
)
(defvar ligo-font-lock-operator-face
	'ligo-font-lock-operator-face)

(defface ligo-font-lock-exception-face
	'(
		(((background light)) (:foreground "dark orange" ))
		(((background dark)) (:foreground "orange" ))
	)
	"Face description for exceptions."
	:group 'ligo
)
(defvar ligo-font-lock-exception-face
	'ligo-font-lock-exception-face)

(defface ligo-font-lock-builtin-type-face
	'(
		(t (:inherit font-lock-type-face ))
	)
	"Face description for builtin types."
	:group 'ligo
)
(defvar ligo-font-lock-builtin-type-face
	'ligo-font-lock-builtin-type-face)

(defface ligo-font-lock-storage-class-face
	'(
		(t (:inherit font-lock-keyword-face ))
	)
	"Face description for storage classes."
	:group 'ligo
)
(defvar ligo-font-lock-storage-class-face
	'ligo-font-lock-storage-class-face)

(defface ligo-font-lock-builtin-module-face
	'(
		(t (:inherit font-lock-function-name-face ))
	)
	"Face description for builtin modules."
	:group 'ligo
)
(defvar ligo-font-lock-builtin-module-face
	'ligo-font-lock-builtin-module-face)

(defface ligo-font-lock-structure-face
	'(
		(t (:inherit font-lock-constant-face ))
	)
	"Face description for structures."
	:group 'ligo
)
(defvar ligo-font-lock-structure-face
	'ligo-font-lock-structure-face)

(defface ligo-font-lock-type-def-face
	'(
		(t (:inherit font-lock-type-face ))
	)
	"Face description for type definitions."
	:group 'ligo
)
(defvar ligo-font-lock-type-def-face
	'ligo-font-lock-type-def-face)

(defface ligo-font-lock-special-char-face
	'(
		(t (:inherit font-lock-string-face ))
	)
	"Face description for special characters."
	:group 'ligo
)
(defvar ligo-font-lock-special-char-face
	'ligo-font-lock-special-char-face)

(defface ligo-font-lock-special-comment-face
	'(
		(t (:inherit font-lock-comment-face ))
	)
	"Face description for special comments."
	:group 'ligo
)
(defvar ligo-font-lock-special-comment-face
	'ligo-font-lock-special-comment-face)

(defface ligo-font-lock-error-face
	'(
		(t (:inherit error ))
	)
	"Face description for errors."
	:group 'ligo
)
(defvar ligo-font-lock-error-face
	'ligo-font-lock-error-face)

(defface ligo-font-lock-todo-face
	'(
		(t (:inherit highlight ))
	)
	"Face description for todos."
	:group 'ligo
)
(defvar ligo-font-lock-todo-face
	'ligo-font-lock-todo-face)

(defun religo-syntax-table ()
	"Syntax table"
	(let ((st (make-syntax-table)))
	(modify-syntax-entry ?_ "w" st)
	(modify-syntax-entry ?' "_" st)
	(modify-syntax-entry ?. "'" st)
	(modify-syntax-entry ?^ "." st)
	(modify-syntax-entry ?# "." st)
	(modify-syntax-entry ?< "." st)
	(modify-syntax-entry ?> "." st)
	(modify-syntax-entry ?/ "." st)
	(modify-syntax-entry ?* "." st)
	(modify-syntax-entry ?- "." st)
	(modify-syntax-entry ?+ "." st)
	(modify-syntax-entry ?! "." st)
	(modify-syntax-entry ?\" "\"" st)
	(modify-syntax-entry ?* ". 23" st)
	(modify-syntax-entry ?
 "> b" st)
	(modify-syntax-entry ?/ ". 124b" st)
	st))

(defvar religo-font-lock-defaults
	`(
		(,"\\[@.*\\]"
			. ligo-font-lock-attribute-face
		)
		(,"^\\(#[a-zA-Z]+\\)"
			. font-lock-preprocessor-face
		)
		(,"\\b\\(switch\\|if\\|else\\|assert\\|failwith\\)\\b"
			. ligo-font-lock-conditional-face
		)
		(,"\\b\\(let\\)\\b[ ]*\\b\\(rec\\|\\)\\b[ ]*\\b\\([a-zA-Z$_][a-zA-Z0-9$_]*\\|\\)"
			(1 font-lock-keyword-face)
			(2 ligo-font-lock-storage-class-face)
			(3 font-lock-variable-name-face)
		)
		(,"\\b[-+]?\\([0-9]+\\)\\(n\\|\\tz\\|tez\\|mutez\\|\\)\\b"
			. ligo-font-lock-number-face
		)
		(,"[ ]*\\(-\\|+\\|/\\|mod\\|land\\|lor\\|lxor\\|lsl\\|lsr\\|&&\\|||\\|<\\|>\\|!=\\|<=\\|>=\\)[ ]*"
			. ligo-font-lock-operator-face
		)
		(,"\\(*\\)"
			. ligo-font-lock-operator-face
		)
		(,"\\b\\(type\\)\\b"
			. font-lock-type-face
		)
		(,"\\b\\([A-Z][a-zA-Z0-9_$]*\\)\\.\\([a-z_][a-zA-Z0-9_$]*\\)\\b"
			(1 ligo-font-lock-structure-face)
			(2 font-lock-variable-name-face)
		)
		(,"\\b\\([A-Z][a-zA-Z0-9_$]*\\)\\b"
			(1 ligo-font-lock-label-face)
		)
	)
	"Syntax highlighting rules for religo")
(defun religo-reload ()
	"Reload the religo-mode code and re-apply the default major mode in the current buffer."
	(interactive)
	(unload-feature 'religo-mode)
	(require 'religo-mode)
	(normal-mode))

(define-derived-mode ligo-reason-mode prog-mode "religo"
	"Major mode for writing religo code."
	(setq font-lock-defaults '(religo-font-lock-defaults))
	(set-syntax-table (religo-syntax-table)))

(add-to-list 'auto-mode-alist '("\\.religo\\'" . ligo-reason-mode))
(provide 'religo-mode)
