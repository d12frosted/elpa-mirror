;;; wal-mode.el --- A major mode for the WAL programming language  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Lucas Klemmer

;; Author: Lucas Klemmer <lucas.klemmer@jku.at>
;; Keywords: languages
;; Package-Version: 20220409.1214
;; Package-Commit: 1daaf882824e8483419dc999c2d5507ad30cc929
;; URL: https://github.com/LucasKl/wal-major-mode
;; Version: 1.0
;; Package-Requires: ((emacs "25.1"))

;;; License:

;; BSD 3-Clause License

;; Copyright (c) 2022, Lucas Klemmer
;; All rights reserved.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:

;; 1. Redistributions of source code must retain the above copyright notice, this
;;    list of conditions and the following disclaimer.

;; 2. Redistributions in binary form must reproduce the above copyright notice,
;;    this list of conditions and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.

;; 3. Neither the name of the copyright holder nor the names of its
;;    contributors may be used to endorse or promote products derived from
;;    this software without specific prior written permission.

;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:
;; An Emacs major mode for WAL.

;;; Code:

(require 'ido)
(require 'comint)

;; ------------------------------ Highlighting ------------------------------
(defconst wal-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; ; is a comment starter
    (modify-syntax-entry ?\; "<" table)
    ;; \n is a comment ender
    (modify-syntax-entry ?\n ">" table)
    table))

(defconst wal-op-arithmetic '("+" "-" "*" "/" "fdiv" "**") )
(defconst wal-op-logical '(">" "<" "=" "<=" ">=" "&&" "||") )
(defconst wal-op-keywords '("print" "printf" "set" "let" "call" "import"
			    "require" "defun" "list" "first" "second"
			    "slice" "array" "rest" "map" "mapa"
			    "eval" "quote" "get" "seta" "geta") )
(defconst wal-op-control-flow '("if" "cond" "when" "unless" "while" "for") )
(defconst wal-op-special '("whenever" "find" "count" "groups" "in-group" "in-groups"
			   "in-scope" "in-scopes" "resolve-group" "resolve-scope") )

(defconst wal-keywords-regexp (regexp-opt wal-op-keywords 'words))
(defconst wal-arithmetic-regexp (regexp-opt wal-op-arithmetic 'words))
(defconst wal-logical-regexp (regexp-opt wal-op-logical 'words))
(defconst wal-control-flow-regexp (regexp-opt wal-op-control-flow 'words))
(defconst wal-special-regexp (regexp-opt wal-op-special 'words))

(defconst wal-highlights
  `(;; Color function definitions
    ("defun \\([/[:alnum:].-]+\\)" 1 'font-lock-function-name-face)
    (,wal-keywords-regexp . font-lock-keyword-face)
    (,wal-arithmetic-regexp . font-lock-keyword-face)
    (,wal-logical-regexp . font-lock-keyword-face)
    (,wal-control-flow-regexp . font-lock-keyword-face)
    (,wal-special-regexp . font-lock-type-face)

    ;; Color constants
    ("#t\\|#f" . font-lock-constant-face)
    ;; Color user function calls
    ("\(\s*\\(\\w+\\)\s" 1 'font-lock-builtin-face)
    ;; Color variable bindings
    ("\\(set\\|let\\|for\\) \\[\\(\\w+\\)\s" 2 'font-lock-variable-name-face)
    ;; Color timed evaluation - for now only integers and symbols
    ("[@#~][/[:alnum:].-]+" . font-lock-string-face)
    ;; Color numbers
    ("-?[[:digit:]]+" . font-lock-constant-face)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.wal\\'" . wal-mode))

;; ------------------------------ Completion ------------------------------
(defconst wal-keywords
  '("!" "atom?" "fold" "int?" "range" "symbol?" "!="
    "average" "fold/signal" "lambda" "require" "type"
    "&&" "call" "for" "last" "resolve-group"
    "unalias" "*" "case" "get" "length"
    "resolve-scope" "unless" "**" "cond" "geta"
    "let" "rest" "unload" "+" "convert/bin" "geta/default"
    "letret" "reval" "unset-scope" "-" "count"
    "groups" "list" "second" "when" "/"
    "defun" "help" "list?" "set" "whenever"
    "<" "do" "if" "load" "set-scope"
    "while" "<=" "eval" "import" "map"
    "seta" "zip" "=" "exit" "in"
    "mapa" "slice" "||" ">" "fdiv"
    "in-group" "max" "step" ">=" "find"
    "in-groups" "min" "string->int" "alias" "find/g"
    "in-scope" "print" "string?" "all-scopes" "first"
    "inc" "printf" "sum" "array" "fn"
    "int->string" "quote" "symbol->string"))

(defun wal-complete-symbol ()
  "Perform keyword completion on current symbol.
This uses variable `ido-mode' user interface for completion.
Source: http://xahlee.info/emacs/emacs/elisp_keyword_completion.html"
  (interactive)
  (let* (
	 ($bds (bounds-of-thing-at-point 'symbol))
	 ($p1 (car $bds))
	 ($p2 (cdr $bds))
	 ($current-sym
	  (if  (or (null $p1) (null $p2) (equal $p1 $p2))
	      ""
	    (buffer-substring-no-properties $p1 $p2)))
	 $result-sym)
    (when (not $current-sym) (setq $current-sym ""))
    (setq $result-sym
	  (ido-completing-read "" wal-keywords nil nil $current-sym ))
    (delete-region $p1 $p2)
    (insert $result-sym)))

;; ------------------------------ WAL eval ------------------------------
(defun wal-eval-sexpr-behind ()
  "Evaluate the sexpr behind point."
  (interactive)
  (let (start end sexpr)
    (setq end (point))
    (backward-sexp)
    (setq start (point))
    (goto-char end)
    (setq sexpr (replace-regexp-in-string "\n" " " (buffer-substring-no-properties start end)))
    (wal-eval-sexpr sexpr)))

(defun wal-eval-sexpr-forward ()
  "Evaluate the sexpr in front of point."
  (interactive)
  (let (start end sexpr)
    (setq start (point))
    (forward-sexp)
    (setq end (point))
    (goto-char start)
    (setq sexpr (replace-regexp-in-string "\n" " " (buffer-substring-no-properties start end)))
    (wal-eval-sexpr sexpr)))

(defun wal-eval-buffer ()
  "Evaluate the complete buffer in the WAL process."
  (interactive)
  (let (buffer-content sexpr)
    (setq buffer-content (buffer-substring-no-properties 1 (buffer-size)))
    ;; wrap everything in a do function
    (setq sexpr (concat "(do " buffer-content ")"))
    ;; remove interpreter line
    (setq sexpr (replace-regexp-in-string "#\!.*\n" "" sexpr))
    (wal-eval-sexpr sexpr)))

(defun wal-eval-sexpr (sexpr)
  "Send the SEXPR to the WAL process."
  ;; remove comments and blank lines
  (setq sexpr (replace-regexp-in-string ";.*\n\\|^[[:space:]]+$" "" sexpr))
  ;; remove line breaks
  (setq sexpr (replace-regexp-in-string "\n" " " sexpr))
  ;; remove unnecessary whitespace
  (setq sexpr (replace-regexp-in-string "[[:space:]]+" " " sexpr))
  (with-current-buffer (get-buffer "*WAL*")
    (comint-send-string "*WAL*" sexpr)
    (comint-send-input)))

;; Create Major Mode
;;;###autoload
(define-derived-mode wal-mode scheme-mode "WAL Mode"
  :syntax-table wal-mode-syntax-table
  (setq font-lock-defaults '(wal-highlights))
  (font-lock-ensure)
  (local-set-key (kbd "M-<tab>") 'wal-complete-symbol)
  (local-set-key (kbd "C-x C-e") 'wal-eval-sexpr-behind)
  (local-set-key (kbd "C-M-x") 'wal-eval-sexpr-forward))


(defvar wal-prompt-regexp "^>->" "WAL Prompt >->.")

(defvar wal-cli-arguments '()
  "Commandline arguments to pass to `wal-cli'.")

(defvar wal-mode-map
  (let ((map (nconc (make-sparse-keymap) comint-mode-map)))
    ;; example definition
    (define-key map "\t" 'completion-at-point)
    map)
  "Basic mode map for `wal-run'.")

(defun wal-repl-initialize ()
  "Helper function to initialize WAL."
  (setq comint-process-echoes t)
  (setq comint-use-prompt-regexp t))

(defun wal-run ()
  "Start a WAL REPL and connects to it in a buffer called *WAL*."
  (interactive)
  (let (wal-repl-buffer)
    (setq wal-repl-buffer (get-buffer-create "*WAL*"))
    (apply #'make-comint-in-buffer "Wal" wal-repl-buffer
	   "wal" '())
    (display-buffer "*WAL*")))

(define-derived-mode wal-repl-mode comint-mode "Wal"
  "Major mode for `run-wal'.

\\<wal-mode-map>"
  nil "Wal"
  ;; this sets up the prompt so it matches things like: [foo@bar]
  (setq comint-prompt-regexp wal-prompt-regexp)
  ;; this makes it read only; a contentious subject as some prefer the
  ;; buffer to be overwritable.
  (setq comint-prompt-read-only t)
  ;; this makes it so commands like M-{ and M-} work.
  (set (make-local-variable 'paragraph-separate) "\\'")
  (set (make-local-variable 'paragraph-start) wal-prompt-regexp)
  (wal-repl-initialize))

(provide 'wal-mode)
;;; wal-mode.el ends here
