;;; eslint-fix.el --- Fix JavaScript files using ESLint

;; Copyright (C) 2016 Neri Marschik
;; This package uses the MIT License.
;; See the LICENSE file.

;; Author: Neri Marschik <marschik_neri@cyberagent.co.jp>
;; Version: 1.0
;; Package-Version: 20211005.221
;; Package-Commit: 636bf8d8797bdd58f1b543c9d3f4910e3ce879ab
;; Package-Requires: ()
;; Keywords: tools, javascript, eslint, lint, formatting, style
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

(defgroup eslint-fix nil
  "Fix JavaScript linting issues with ‘eslint-fix’."
  :link '(function-link eslint-fix)
  :tag "ESLint Fix"
  :group 'tools)

(defcustom eslint-fix-executable "eslint"
  "The ESLint executable to use."
  :tag "ESLint Executable"
  :type 'string)

(defcustom eslint-fix-options nil
  "Additional options to pass to ESLint (e.g. “--quiet”)."
  :tag "ESLint Options"
  :type '(repeat string))

;;;###autoload
(defun eslint-fix ()
  "Format the current file with ESLint."
  (interactive)
  (unless buffer-file-name
    (error "ESLint requires a file-visiting buffer"))
  (when (buffer-modified-p)
    (if (y-or-n-p (format "Save file %s? " buffer-file-name))
        (save-buffer)
      (error "ESLint may only be run on an unmodified buffer")))

  (let ((eslint (executable-find eslint-fix-executable))
        (options (append eslint-fix-options
                         (list "--fix" buffer-file-name))))
    (unless eslint
      (error "Executable ‘%s’ not found" eslint-fix-executable))
    (apply #'call-process eslint nil "*ESLint Errors*" nil options)
    (revert-buffer t t t)))

;;;###autoload
(define-minor-mode eslint-fix-auto-mode
  "Run `eslint-fix' after save."
  :group 'eslint-fix
  (if eslint-fix-auto-mode
      (add-hook 'after-save-hook #'eslint-fix nil t)
    (remove-hook 'after-save-hook #'eslint-fix t)))

(provide 'eslint-fix)

;;; eslint-fix.el ends here
