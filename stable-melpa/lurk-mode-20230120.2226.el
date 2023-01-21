;;; lurk-mode.el --- A major mode for editing lurk files -*- lexical-binding: t; -*-
;; Authors: Jeff Weiss <jweiss@protocol.ai>
;; Maintainer: Jeff Weiss <jweiss@protocol.ai>
;; URL: http://github.com/lurk-lang/lurk-emacs
;; Package-Version: 20230120.2226
;; Package-Commit: 59a3f956944a5ddd43cfd57deeff6b647fc46554
;; Keywords: languages lurk lisp
;; Version: 0.1.8
;; SPDX-License-Identifier: Apache-2.0 AND MIT
;; Package-Requires: ((emacs "25.1"))
;;; Commentary:

;; A major mode based on scheme.  Also provides a REPL buffer.

;; To start editing lurk files, first run (or add to your init files)

;;   (require 'lurk-mode)

;; To get an interactive session, first make sure the custom variable
;; `lurk-executable' is set.

;;   M-x customize-variable RET lurk-executable

;; then set the value to be the location of the lurk binary (either
;; full path or leave as-is if it's installed on PATH).  Next run

;;   M-x lurk-repl

;; In a .lurk source file, you can run M-x lurk-eval-last-expression
;; to evaluate the given expression preceding point. The result will
;; be shown in the repl buffer.

;;; Code:
(require 'comint)
(require 'inf-lisp)
(defconst lurk-keywords
  '("lambda" "let" "letrec" "cons" "strcons" "hide" "begin" "car" "cdr"
    "commit" "num" "comm" "char" "eval" "open" "secret" "atom" "emit" "if"
    "current-env"))

(defconst lurk-font-lock-keywords
  `((,(regexp-opt lurk-keywords 'words) . (0 font-lock-keyword-face))))

;;;###autoload
(define-derived-mode lurk-mode scheme-mode "Lurk"
  "Lurk mode is a major mode for editing Lurk files.

\\{lurk-mode-map}"

  (add-hook 'lurk-mode-hook
	    (lambda ()
	      (font-lock-add-keywords nil lurk-font-lock-keywords))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lurk\\'" . lurk-mode))

(defcustom lurk-executable "lurkrs"
  "Location of the lurk binary."
  :type 'string
  :group 'lurk)

;;;###autoload
(defun inferior-lurk (cmd)
  "Run an inferior Lurk process, input and output via buffer `*inferior-lurk*'.
If there is a process already running in `*inferior-lurk*', just switch
to that buffer.

With argument, allows you to edit the command line (default is value
of `inferior-lisp-program').  Runs the hooks from
`inferior-lisp-mode-hook' (after the `comint-mode-hook' is run).

If any parts of the command name contains spaces, they should be
quoted using shell quote syntax.

\(Type \\[describe-mode] in the process buffer for a list of commands.)"
  (interactive (list (if current-prefix-arg
			 (read-string "Run lisp: " inferior-lisp-program)
		       inferior-lisp-program)))
  (if (not (comint-check-proc "*inferior-lurk*"))
      (let ((cmdlist (split-string-shell-command cmd)))
	(set-buffer (apply (function make-comint)
			   "inferior-lurk" (car cmdlist) nil (cdr cmdlist)))
	(inferior-lisp-mode)))
  (setq inferior-lisp-buffer "*inferior-lurk*")
  (pop-to-buffer-same-window "*inferior-lurk*"))

;;;###autoload
(defun lurk-repl ()
  "Start lurk repl using the binary specified in `lurk-executable'."
  (interactive)
  (inferior-lurk lurk-executable)
  (rename-buffer "*lurk*"))

(defun lurk-eval-last-sexp ()
  "Send the last sexp to the lurk repl to be evaluated."
  (interactive)
  (append-to-buffer "*lurk*"
		    (point)
		    (save-excursion (backward-sexp) (point)))
  (with-current-buffer "*lurk*"
    (comint-send-input)))

(defvar lurk-mode-map nil "Keymap for `lurk-mode'")
(progn
  (setq lurk-mode-map (make-sparse-keymap))
  (define-key lurk-mode-map (kbd "C-c C-r") 'lurk-repl)
  (define-key lurk-mode-map (kbd "C-x C-e") 'lurk-eval-last-sexp))

(provide 'lurk-mode)
;;; lurk-mode.el ends here

