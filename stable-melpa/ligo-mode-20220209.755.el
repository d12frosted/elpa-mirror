;;; ligo-mode.el --- A major mode for editing LIGO source code

;; Version: 0.2.0
;; Package-Version: 20220209.755
;; Package-Commit: d95e515dd210302627b8da86df747ccef9056db7
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

(defgroup ligo nil
  "Support for LIGO code.";  :link '(url-link "https://www.ligolang.org/")
  :group 'languages)

(defcustom ligo-squirrel-bin "ligo-squirrel"
  "Path to LIGO language server executable."
  :type 'string
   :group 'ligo)
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
(defun ligo-syntax-table ()
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
	(modify-syntax-entry ?\n "> b" st)
	(modify-syntax-entry ?/ ". 12b" st)
	(modify-syntax-entry ?* ". 23" st)
	(modify-syntax-entry ?\( "()1n" st)
	(modify-syntax-entry ?\) ")(4n" st)
	st))

(defvar ligo-font-lock-defaults
	`(
		(,"\\[@.*\\]"
			. ligo-font-lock-attribute-face
		)
		(,"^\\(#[a-zA-Z]+\\)"
			. font-lock-preprocessor-face
		)
		(,"\\b\\(case\\|with\\|if\\|then\\|else\\|assert\\|failwith\\|begin\\|end\\|in\\|is\\|from\\|skip\\|block\\|contains\\|to\\|step\\|of\\|while\\|for\\|remove\\)\\b"
			. ligo-font-lock-conditional-face
		)
		(,"\\b\\(function\\)\\b[ ]*\\b\\([a-zA-Z$_][a-zA-Z0-9$_]*\\|\\)"
			(1 font-lock-keyword-face)
			(2 font-lock-variable-name-face)
		)
		(,"\\b[-+]?\\([0-9]+\\)\\(n\\|\\tz\\|tez\\|mutez\\|\\)\\b"
			. ligo-font-lock-number-face
		)
		(,"[ ]*\\(-\\|+\\|/\\|mod\\|land\\|lor\\|lxor\\|lsl\\|lsr\\|&&\\|||\\|<\\|>\\|=/=\\|<=\\|>=\\)[ ]*"
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
		(,"\\b\\(const\\|var\\)\\b"
			(1 font-lock-keyword-face)
		)
	)
	"Syntax highlighting rules for ligo")
(defun ligo-reload ()
	"Reload the ligo-mode code and re-apply the default major mode in the current buffer."
	(interactive)
	(unload-feature 'ligo-mode)
	(require 'ligo-mode)
	(normal-mode))

(define-derived-mode ligo-pascal-mode prog-mode "ligo"
	"Major mode for writing ligo code."
	(setq font-lock-defaults '(ligo-font-lock-defaults))
	(set-syntax-table (ligo-syntax-table)))

(add-to-list 'auto-mode-alist '("\\.ligo\\'" . ligo-pascal-mode))
(provide 'ligo-mode)
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
			(3 font-lock-variable-name-face)
		)
		(,"\\b[-+]?\\([0-9]+\\)\\(n\\|\\tz\\|tez\\|mutez\\|\\)\\b"
			. ligo-font-lock-number-face
		)
		(,"[ ]*\\(::\\|-\\|+\\|/\\|mod\\|land\\|lor\\|lxor\\|lsl\\|lsr\\|&&\\|||\\|<\\|>\\|<>\\|<=\\|>=\\)[ ]*"
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

;;; ligo-mode.el ends here
