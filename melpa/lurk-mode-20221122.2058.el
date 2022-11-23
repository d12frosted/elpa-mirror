;;; lurk-mode.el --- A major mode for editing lurk files -*- lexical-binding: t; -*-
;; Authors: Jeff Weiss <jweiss@protocol.ai>
;; Maintainer: Jeff Weiss <jweiss@protocol.ai>
;; URL: http://github.com/lurk-lang/lurk-emacs
;; Package-Version: 20221122.2058
;; Package-Commit: bd7cf661ccb31bfbfab542018c361bd79064d4f4
;; Keywords: languages lurk lisp
;; Version: 0.1.7
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
(defun lurk-repl ()
  "Start lurk repl using the binary specified in `lurk-executable'."
  (interactive)
  (run-lisp lurk-executable)
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

