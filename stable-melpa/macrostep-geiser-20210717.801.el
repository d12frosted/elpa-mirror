;;; macrostep-geiser.el --- Macrostep for `geiser' -*- lexical-binding: t -*-

;; Copyright (C) 2021  Nikita Bloshchanevich <nikblos@outlook.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Author: Nikita Bloshchanevich
;; URL: https://github.com/nbfalcon/macrostep-geiser
;; Package-Version: 20210717.801
;; Package-Commit: f6a2d5bb96ade4f23df557649af87ebd0cc45125
;; Keywords: languages, scheme
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.4") (macrostep "0.9") (geiser "0.12"))

;;; Commentary:

;; Provides `macrostep' support for `geiser' and `cider'.
;;
;; To enable `macrostep' in `geiser-mode' buffer, execute
;; `macrostep-geiser-setup'. The latter function can be added to
;; `geiser-mode-hook' and `geiser-repl-mode-hook':
;;
;; (eval-after-load 'geiser-mode '(add-hook 'geiser-mode-hook #'macrostep-geiser-setup))
;; (eval-after-load 'geiser-repl '(add-hook 'geiser-repl-mode-hook #'macrostep-geiser-setup))
;;
;; Or, using `use-package':
;;
;; (use-package macrostep-geiser
;;   :after geiser-mode
;;   :config (add-hook 'geiser-mode-hook #'macrostep-geiser-setup))

;; (use-package macrostep-geiser
;;   :after geiser-repl
;;   :config (add-hook 'geiser-repl-mode-hook #'macrostep-geiser-setup))

;; Additionally, for `cider' integration:
;;
;; (eval-after-load 'cider-mode '(add-hook 'cider-mode-hook #'macrostep-geiser-setup))
;;
;; Or, using `use-package':
;;
;; (use-package macrostep-geiser
;;   :after cider-mode
;;   :config (add-hook 'cider-mode-hook #'macrostep-geiser-setup))

;;; Code:

(require 'subr-x)

;;; macrostep: detection functions

(defun macrostep-geiser-macro-form-p (_sexp _env)
  "`macrostep-macro-form-p' for `geiser'."
  ;; `geiser' doesn't expose a way to check if a form is macro; the macroexpand
  ;; command expands even non-macro forms, yielding (%app ...).
  t)

(defun macrostep-geiser-sexp-at-point (&optional start end)
  "`macrostep-sexp-at-point-function' for `geiser'.
START and END are the bounds returned by
`macrostep-sexp-bounds', defaulting to the sexp after `point'."
  (buffer-substring-no-properties (or start (point)) (or end (scan-lists (point) 1 0))))

;;; Expansion: back-ends

(defun macrostep-geiser-geiser-expand (str &optional expand-all?)
  "Expand STR using `geiser'.
See `macrostep-geiser-expand-function' for EXPAND-ALL?."
  (require 'geiser-eval)
  (declare-function geiser-eval--send/wait "geiser-eval" (code &optional timeout buffer))
  (declare-function geiser-eval--retort-error "geiser-eval" (ret))
  (declare-function geiser-eval--retort-result "geiser-eval" (ret))
  (let* ((ret (geiser-eval--send/wait `(:eval (:ge macroexpand (quote (:scm ,str))
                                               ,(if expand-all? :t :f)))))
         (err (geiser-eval--retort-error ret)))
    (when err
      (user-error "Macro expansion failed: %s" err))
    (geiser-eval--retort-result ret)))

(defun macrostep-geiser-cider-expand (str &optional expand-all?)
  "Expand STR using `cider'.
See `macrostep-geiser-expand-function' for EXPAND-ALL?."
  (require 'cider-macroexpansion)
  (declare-function cider-sync-request:macroexpand "cider-macroexpansion"
                    (expander expr &optional display-namespaces))
  (or (cider-sync-request:macroexpand (if expand-all? "macroexpand" "macroexpand-1") str)
      (user-error "Macro expansion failed")))

;;; Expansion

(defvar macrostep-geiser-expand-function #'macrostep-geiser-geiser-expand
  "Function used to expand a macro string.
It is called with to arguments: the string to be expanded, and a
boolean indicating whether the macro should be expanded
recursively or just one level of it (`macroexpand' or
`macroexpand-1').")

(define-minor-mode macrostep-geiser-expand-all-mode
  "Make `macrostep-geiser' expand macros recursively."
  :init-value nil
  :lighter nil)

(defun macrostep-geiser--compare-expansions (a b)
  "Compare A and B for equality, folding whitespace.
\"(A B)\" = \"(A  B)\"."
  (string= (replace-regexp-in-string "[[:space:]]+" " " (string-trim a) t t)
           (replace-regexp-in-string "[[:space:]]+" " " (string-trim b) t t)))

(defun macrostep-geiser-expand-1 (str &optional _env)
  "Expand one level of STR using `macrostep-geiser'.
STR is the macro form as a string."
  (let* ((res (funcall macrostep-geiser-expand-function str
                       macrostep-geiser-expand-all-mode)))
    (when (macrostep-geiser--compare-expansions str res)
      (user-error "Final macro expansion"))
    ;; Adjust indentation: indent each line by the offset of the current column
    ;; from the start column, since expansions are for non-indented forms
    (let ((res (string-trim-right res)))
      (replace-regexp-in-string
       "\n" (concat "\n" (make-string (current-column) ?\ )) res t t))))

(defun macrostep-geiser-expand-all (&optional arg)
  "Recursively expand the macro at `point'.
Only works with `macrostep-geiser'. ARG is passed to
`macrostep-expand'."
  (interactive "P")
  (require 'macrostep)
  (declare-function macrostep-expand "macrostep" (&optional arg))
  (let ((macrostep-geiser-expand-all-mode t))
    (macrostep-expand arg)))

;;; macrostep: printing

(defface macrostep-geiser-expanded-text-face '((t :inherit macrostep-expand-text))
  "Face used for `macrostep-geiser' expansions."
  :group 'macrostep-geiser)

(defun macrostep-geiser-print (expanded &rest _)
  "`macrostep-print-function' for `macrostep-geiser'.
EXPANDED is the return value of `macrostep-geiser-expand-1'."
  (insert (propertize expanded 'face 'macrostep-geiser-expanded-text-face)))

;;; Set-up

;;;###autoload
(defun macrostep-geiser-setup ()
  "Set-up `macrostep' to use `geiser'."
  (interactive)
  (defvar macrostep-macro-form-p-function)
  (defvar macrostep-sexp-at-point-function)
  (defvar macrostep-expand-1-function)
  (defvar macrostep-print-function)
  (defvar macrostep-environment-at-point-function)
  (setq-local macrostep-macro-form-p-function #'macrostep-geiser-macro-form-p)
  (setq-local macrostep-sexp-at-point-function #'macrostep-geiser-sexp-at-point)
  (setq-local macrostep-expand-1-function #'macrostep-geiser-expand-1)
  (setq-local macrostep-print-function #'macrostep-geiser-print)
  (setq-local macrostep-environment-at-point-function #'ignore)
  (setq-local macrostep-geiser-expand-function
              (cond ((bound-and-true-p cider-mode) #'macrostep-geiser-cider-expand)
                    (t #'macrostep-geiser-geiser-expand))))

(provide 'macrostep-geiser)
;;; macrostep-geiser.el ends here
