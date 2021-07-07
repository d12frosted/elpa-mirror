;;; eslint-fix.el --- Fix JavaScript files using ESLint

;; Copyright (C) 2016 Neri Marschik
;; This package uses the MIT License.
;; See the LICENSE file.

;; Author: Neri Marschik <marschik_neri@cyberagent.co.jp>
;; Version: 1.0
;; Package-Version: 20160819.736
;; Package-Commit: be90d1e78b1dfd43b6b3b1c06868539e2ac27d3a
;; Package-Requires: ()
;; Keywords: javascript, eslint, lint, formatting, style
;; URL: https://github.com/codesuki/eslint-fix

;;; Commentary:
;;
;; This file provides `eslint-fix', which fixes the current file using ESLint.
;;
;; Usage:
;;     M-x eslint-fix
;;
;;     To automatically format after saving:
;;     (Choose depending on your favorite mode.)
;;
;;     (eval-after-load 'js-mode
;;       '(add-hook 'js-mode-hook (lambda () (add-hook 'after-save-hook 'eslint-fix nil t))))
;;
;;     (eval-after-load 'js2-mode
;;       '(add-hook 'js2-mode-hook (lambda () (add-hook 'after-save-hook 'eslint-fix nil t))))

;;; Code:

;;;###autoload
(defun eslint-fix ()
  "Format the current file with ESLint."
  (interactive)
  (if (executable-find "eslint")
      (progn (call-process "eslint" nil "*ESLint Errors*" nil "--fix" buffer-file-name)
             (revert-buffer t t t))
    (message "ESLint not found.")))

(provide 'eslint-fix)

;;; eslint-fix.el ends here
