;;; flymake-json.el --- A flymake handler for json using jsonlint
;;
;;; Author: Steve Purcell <steve@sanityinc.com>
;;; Homepage: https://github.com/purcell/flymake-json
;;; Version: DEV
;; Package-Version: 20130117.1659
;; Package-Commit: ad8e482db1ad29e23bdd9d089b9bc3615649ce65
;;; Package-Requires: ((flymake-easy "0.1"))
;;
;;; Commentary:
;;
;; Usage:
;;   (require 'flymake-json)
;;
;; Then, if you're using `json-mode':
;;
;;   (add-hook 'json-mode 'flymake-json-load)
;;
;; or, if you use `js-mode' for json:
;;
;;   (add-hook 'js-mode-hook 'flymake-json-maybe-load)
;;
;; otherwise:
;;
;;   (add-hook 'find-file-hook 'flymake-json-maybe-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defconst flymake-json-err-line-patterns
  '(("^\\(.+\\)\: line \\([0-9]+\\), col \\([0-9]+\\), \\(.+\\)$" nil 2 3 4)))

(defun flymake-json-command (filename)
  "Construct a command that flymake can use to check json source."
  (list "jsonlint" "-c" "-q" filename))


;;;###autoload
(defun flymake-json-load ()
  "Configure flymake mode to check the current buffer's javascript syntax."
  (interactive)
  (flymake-easy-load 'flymake-json-command
                     flymake-json-err-line-patterns
                     'tempdir
                     "json"))

;;;###autoload
(defun flymake-json-maybe-load ()
  "Call `flymake-json-load' if this file appears to be json."
  (interactive)
  (if (and buffer-file-name
           (string= "json" (file-name-extension buffer-file-name)))
      (flymake-json-load)))


(provide 'flymake-json)
;;; flymake-json.el ends here
