;;; lurk-mode.el --- A major mode for editing lurk files -*- lexical-binding: t; -*-
;; Authors: Jeff Weiss <jweiss@protocol.ai>
;; Maintainer: Jeff Weiss <jweiss@protocol.ai>
;; URL: http://github.com/lurk-lang/lurk-emacs
;; Package-Version: 20221113.219
;; Package-Commit: 0eb856f771aa18e55db6b027c75b944a92c15464
;; Keywords: languages lurk lisp
;; Version: 0.1.5
;; SPDX-License-Identifier: Apache-2.0 AND MIT
;; Package-Requires: ((emacs "25.1"))
;;; Commentary:

;; A major mode based on scheme.  Also provides a REPL buffer.

;; To start editing lurk files, first run (or add to your init files)

;;   (require 'lurk-mode)

;; To get an interactive session, first make sure the custom variable
;; `lurk-executable' is set.

;;   M-x customize-variable RET lurk-executable

;; then set the value to be the full path to the lurk binary.  Next run

;;   M-x lurk-repl

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
  "Lurk mode is a major mode for editing Lurk files."

  (add-hook 'lurk-mode-hook (lambda () (font-lock-add-keywords nil lurk-font-lock-keywords))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lurk\\'" . lurk-mode))

(defcustom lurk-executable "lurk"
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

(provide 'lurk-mode)
;;; lurk-mode.el ends here

