;;; flymake-shell.el --- A flymake syntax-checker for shell scripts
;;
;;; Copyright (C) 2011 Steve Purcell
;;; Author: Steve Purcell <steve@sanityinc.com>
;;; URL: https://github.com/purcell/flymake-shell
;; Package-Version: 20121104.1900
;; Package-Commit: ec097bd77db5523a04ceb15a128e01689d36fb90
;;; Version: DEV
;;; Package-Requires: ((flymake-easy "0.1"))
;;;
;;; Commentary:

;; Usage:

;;   (require 'flymake-shell)
;;   (add-hook 'sh-set-shell-hook 'flymake-shell-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defconst flymake-shell-supported-shells '(bash zsh sh dash))

(defconst flymake-shell-err-line-pattern-re
  '(("^\\(.+\\): line \\([0-9]+\\): \\([^`].+\\)$" 1 2 nil 3) ; bash
    ("^\\(.+\\): ?\\([0-9]+\\): \\(.+\\)$" 1 2 nil 3)) ; zsh / dash
  "Regexp matching shell error messages.")

(defun flymake-shell-command (filename)
  "Construct a command that flymake can use to check shell source."
  (list (symbol-name sh-shell) "-n" filename))

;;;###autoload
(defun flymake-shell-load ()
  "Configure flymake mode to check the current buffer's shell-script syntax."
  (interactive)
  (unless (eq 'sh-mode major-mode)
    (error "Cannot enable flymake-shell in this major mode"))
  (if (memq sh-shell flymake-shell-supported-shells)
      (flymake-easy-load 'flymake-shell-command
                         flymake-shell-err-line-pattern-re
                         'tempdir
                         "sh")
    (message "Shell %s is not supported by flymake-shell" sh-shell)))


(provide 'flymake-shell)
;;; flymake-shell.el ends here
