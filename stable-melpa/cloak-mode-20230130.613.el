;;; cloak-mode.el --- A minor mode to cloak sensitive values

;; Copyright © 2022 Erick Navarro
;; Author: Erick Navarro <erick@navarro.io>
;; URL: https://github.com/erickgnavar/cloak-mode
;; Package-Version: 20230130.613
;; Package-Commit: ca0896dfd0a0ee549150233ebd96aa0f65b56afb
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
  (when-let ((raw-regex (cdr (assq major-mode cloak-mode-patterns)))
             ;; We need to iterate over a list of regex so we need to create a list
             ;; in case the defined value is a single regex
             (regex-list (if (listp raw-regex) raw-regex (list raw-regex))))
    (save-excursion
      (dolist (regex regex-list)
        (goto-char (point-min))
        (while (search-forward-regexp regex (point-max) t)
          (if (match-string 1)
              (cloak-mode--cloak-text (match-beginning 1) (match-end 1) flag)))))))

(defun cloak-mode--cloak-text (start end cloak)
  "Cloak text between START and END and replace it with *.
if CLOAK is nil cloaking overlay will be removed."
  (if cloak
      (overlay-put (make-overlay start end) 'display cloak-mode-mask)
    (remove-overlays start end)))

(provide 'cloak-mode)
;;; cloak-mode.el ends here
