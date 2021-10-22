;;; ligo-mode.el --- A major mode for editing LIGO source code

;; Version: 0.1.0
;; Package-Version: 20211011.954
;; Package-Commit: 82acc6eeda3f2f1f9d4ad252a0aad01170a0a57e
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
;;     CameLIGO-specific variables and regexes
;; ------------------------------------------------

(rx-define ligo-caml-type-end
  (or "," ";" "=" eol))

;; Doesn't support "let a: int, b: string" for now
(rx-define ligo-caml-variable-def
  (: symbol-start (group "let") symbol-end (* space)
     (group ligo-lower-ident)))

(defvar ligo-caml-keywords
  '("type" "let" "in" "fun" "failwith" "assert" "with"
    "of" "if" "then" "else" "match"))

(defvar ligo-caml-builtins
  '())

(rx-define ligo-caml-constant
  (or ligo-common-constants
      (: symbol-start "True" symbol-end)
      (: symbol-start "False" symbol-end)))

(defvar ligo-caml-mode-highlights
  `(;; Preprocessor macros
    (,(rx ligo-macro-expr)
     . ((1 font-lock-preprocessor-face) (2 font-lock-string-face)))

    ;; Type definitions ("type foo")
    (,(rx ligo-typedef)
     . ((1 font-lock-keyword-face) (2 font-lock-type-face)))

    ;; Function definitions ("function bar")
    ;;(,(rx ligo-caml-function-def)
    ;; . ((1 font-lock-keyword-face) (2 font-lock-function-name-face)))

    ;; Keywords
    (,(regexp-opt ligo-caml-keywords 'symbols) . font-lock-keyword-face)

    ;; Big_map.remove, Tezos.address
    (,(rx ligo-upper-qname)
     . ((1 font-lock-builtin-face)))

    ;; ": type" annotations
    (,(ligo-type-matcher 'ligo-colon-matcher (rx ligo-caml-type-end))
     . font-lock-type-face)

    ;; Variable definitions ("const x", "var y")
    (,(rx ligo-caml-variable-def)
     . ((1 font-lock-keyword-face) (2 font-lock-variable-name-face)))

    ;; Unqualified builtin functions
    (,(regexp-opt ligo-caml-builtins 'symbols) . font-lock-builtin-face)
    
    ;; Constructors
    (,(rx ligo-upper-ident) . 'ligo-constructor-face)

    ;; Constants: True, False, 0n, 5mutez
    (,(rx ligo-caml-constant) . font-lock-constant-face))
  "Syntax highlighting rules for CameLIGO.")

(defun ligo-caml-mode-syntax-table ()
  "CameLIGO syntax table."
  ; Currently equal to the PascaLIGO one
  (ligo-pascal-mode-syntax-table))


;; ------------------------------------------------
;;     ReasonLIGO-specific variables and regexes
;; ------------------------------------------------

(rx-define ligo-reason-type-end
  (or "," "=" eol))

;; Doesn't support "let a: int, b: string" for now
(rx-define ligo-reason-variable-def
  (: symbol-start (group "let") symbol-end (* space)
     (group ligo-lower-ident)))

(defvar ligo-reason-keywords
  '("type" "let" "failwith" "assert" "if" "then" "else" "switch"))

(defvar ligo-reason-builtins
  '())

(defun ligo-reason-type-context-p ()
  "Returns t if `: expression` is in type context"
  (re-search-backward (rx (or "(" ")" "{" "}" "=" ";" "let")) nil t)
  (cond
    ;; Skip balanced braces and recurse
    ((looking-at (rx (or ")" "}")))
      (progn
        ;; If we see a closing brace, we jump to
        ;; the matching one and recurse
        (forward-char)
        (backward-list)
        (ligo-reason-type-context-p)))

    ;; We're inside curly braces, so we need to distinguish
    ;; between `type a = { foo: bar }` and `let a = { foo: bar }`
    ((looking-at "{")
      (let ((maybe-type
              (re-search-backward
                (rx (or ligo-typedef (: symbol-start "let" symbol-end) ";"))
                nil t)))
        ; Assume type context if either:
        ;   1. There are no "type", "let", and ";", just a bare `x: y`
        ;   2. We're after "type" with neither "let" nor ";" in between
        ; Otherwise (if there is either ";" or "let"), assume value context
        (or (null maybe-type) (looking-at "type"))))

    ; We're not in curly braces, so this is a type annotation.
    ; Restore the match data and return the `:` pos
    (t (progn (message "not in curly") t))))

(defun ligo-reason-type-matcher (limit)
  "Matches `: type` annotations in ReasonLIGO,
   excluding `{record: field}` expressions"
  (when-let* ((colon (re-search-forward ":" limit t))
              (colon-match (match-data)))
    (save-excursion
      (if (ligo-reason-type-context-p)
        (progn
            (set-match-data colon-match)
            colon)
        (progn
          (set-match-data nil)
          nil)))))

(rx-define ligo-reason-constant
  (or ligo-common-constants
      (: symbol-start "true" symbol-end)
      (: symbol-start "false" symbol-end)))

(defvar ligo-reason-mode-highlights
  `(;; Preprocessor macros
    (,(rx ligo-macro-expr)
     . ((1 font-lock-preprocessor-face) (2 font-lock-string-face)))

    ;; Type definitions ("type foo")
    (,(rx ligo-typedef)
     . ((1 font-lock-keyword-face) (2 font-lock-type-face)))

    ;; Variable definitions ("const x", "var y")
    (,(rx ligo-reason-variable-def)
     . ((1 font-lock-keyword-face) (2 font-lock-variable-name-face)))

    ;; Keywords
    (,(regexp-opt ligo-reason-keywords 'symbols) . font-lock-keyword-face)

    ;; Big_map.remove, Tezos.address
    (,(rx ligo-upper-qname)
     . ((1 font-lock-builtin-face)))

    ;; ": type" annotations
    (,(ligo-type-matcher 'ligo-reason-type-matcher (rx ligo-reason-type-end))
     . font-lock-type-face)

    ;; Unqualified builtin functions
    (,(regexp-opt ligo-reason-builtins 'symbols) . font-lock-builtin-face)
    
    ;; Constructors
    (,(rx ligo-upper-ident) . 'ligo-constructor-face)

    ;; Constants: True, False, 0n, 5mutez
    (,(rx ligo-reason-constant) . font-lock-constant-face))
  "Syntax highlighting rules for ReasonLIGO.")

(defun ligo-reason-mode-syntax-table ()
  "ReasonLIGO syntax table."
  (let ((st (ligo-syntax-table)))
    ;; C++/ReasonML style comments
    (modify-syntax-entry ?*  ". 23" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?/  ". 124b" st)
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

;;;###autoload
(define-derived-mode ligo-caml-mode prog-mode "mligo"
  "Major mode for writing CameLIGO code."
  (setq font-lock-defaults '(ligo-caml-mode-highlights))
  (set-syntax-table (ligo-caml-mode-syntax-table)))

;;;###autoload
(define-derived-mode ligo-reason-mode prog-mode "religo"
  "Major mode for writing ReasonLIGO code."
  (setq font-lock-defaults '(ligo-reason-mode-highlights))
  (set-syntax-table (ligo-reason-mode-syntax-table)))

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
(add-to-list 'auto-mode-alist '("\\.mligo\\'" . ligo-caml-mode))
(add-to-list 'auto-mode-alist '("\\.religo\\'" . ligo-reason-mode))

(provide 'ligo-mode)
;;; ligo-mode.el ends here
