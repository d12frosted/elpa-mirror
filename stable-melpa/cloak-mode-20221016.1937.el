;;; cloak-mode.el --- A minor mode to cloak sensitive values

;; Copyright © 2022 Erick Navarro
;; Author: Erick Navarro <erick@navarro.io>
;; URL: https://github.com/erickgnavar/cloak-mode
;; Package-Version: 20221016.1937
;; Package-Commit: 9e10b88f662977a9ac01ae542b108060d9b8d943
;; Version: 0.1.0
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Package-Requires: ((emacs "27.1"))

;;; Commentary:
;; Hide sensitive using pre defined regex patterns per major mode.
;; It allows to define specific regex per each major mode where we want to hide
;; sensitive data

;; Usage: For example if we want to add it to envrc files
;;   (require 'cloak-mode)
;;   (setq cloak-mode-patterns '((envrc-file-mode . "[a-zA-Z0-9_]+[ \t]*=[ \t]*\\(.*+\\)$")))
;;   (global-cloak-mode)

;;; Code:
(defcustom cloak-mode-patterns '()
  "Define patterns per major mode to match values that should be cloaked.
Patterns should only have one capturing group (\(\))."
  :group 'cloak-mode
  :type 'alist)

(defcustom cloak-mode-mask "***"
  "Character used to hide values."
  :group 'cloak-mode
  :type 'string)

;;;###autoload
(define-minor-mode cloak-mode
  "Cloak values using a pattern per major mode."
  :lighter " Cloak"
  (if cloak-mode
      (cloak-mode--toggle t)
    (cloak-mode--toggle nil)))

;;;###autoload
(define-globalized-minor-mode global-cloak-mode
  cloak-mode cloak--initialize
  :group 'cloak-mode)

(defun cloak--initialize ()
  "Enable `cloak-mode' in the current buffer, if appropriate."
  (if (assq major-mode cloak-mode-patterns)
      (cloak-mode)))

(defun cloak-mode--toggle (flag)
  "Run cloaking at current buffer depending of the given FLAG."
  (when-let ((regex (cdr (assq major-mode cloak-mode-patterns))))
    (save-excursion
      (goto-char (point-min))
      (while (search-forward-regexp regex (point-max) t)
        (if (match-string 1)
            (cloak-mode--cloak-text (match-beginning 1) (match-end 1) flag))))))

(defun cloak-mode--cloak-text (start end cloak)
  "Cloak text between START and END and replace it with *.
if CLOAK is nil cloaking property will be removed."
  (if cloak
      (put-text-property start end 'display cloak-mode-mask)
    (remove-text-properties start end '(display))))

(provide 'cloak-mode)
;;; cloak-mode.el ends here
