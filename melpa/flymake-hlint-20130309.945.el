;;; flymake-hlint.el --- A flymake handler for haskell-mode files using hlint
;;
;;; Author: Steve Purcell <steve@sanityinc.com>
;;; URL: https://github.com/purcell/flymake-hlint
;; Package-Version: 20130309.945
;; Package-Commit: d540e250a80a09da3036c16bf86f9deb6d738c9c
;;; Version: DEV
;;; Package-Requires: ((flymake-easy "0.1"))
;;;
;;; Commentary:
;; Usage:
;;   (require 'flymake-hlint)
;;   (add-hook 'haskell-mode-hook 'flymake-hlint-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defconst flymake-hlint-err-line-patterns
  '(("^\\(.*\.hs\\):\\([0-9]+\\):\\([0-9]+\\): \\(.*\\(?:\n.+\\)+\\)" 1 2 3 4)))

(defvar flymake-hlint-executable "hlint"
  "The hlint executable to use for syntax checking.")

(defun flymake-hlint-command (filename)
  "Construct a command that flymake can use to check hlint source."
  (list flymake-hlint-executable filename))

;;;###autoload
(defun flymake-hlint-load ()
  "Configure flymake mode to check the current buffer's hlint syntax."
  (interactive)
  (flymake-easy-load 'flymake-hlint-command
                     flymake-hlint-err-line-patterns
                     'inplace
                     "hs"))

(provide 'flymake-hlint)
;;; flymake-hlint.el ends here
