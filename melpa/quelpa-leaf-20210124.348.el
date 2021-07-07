;;; quelpa-leaf.el --- Quelpa handler for leaf  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  Shen, Jen-Chieh
;; Created date 2020-12-26 22:45:18

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/quelpa/quelpa-leaf
;; Package-Version: 20210124.348
;; Package-Commit: cc13df4a6c6cdf1dea558be5b6e99b6e8d8b4065
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1") (quelpa "1.0") (leaf "4.1.0"))
;; Keyword: package managment elpa leaf

;; This file is NOT part of GNU Emacs.

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

;;; Commentary:
;;
;; quelpa handler for `leaf'
;; See the the repo website for more info:
;; https://github.com/quelpa/quelpa-leaf
;;

;;; Code:

(require 'cl-lib)
(require 'leaf)

(defgroup quelpa-leaf nil
  "quelpa handler for leaf."
  :prefix "quelpa-leaf-"
  :group 'lisp
  :link '(url-link :tag "Repository" "https://github.com/quelpa/quelpa-leaf"))

(defvar quelpa-leaf-packages-list
  (leaf-list quelpa)
  "List of dependent packages.")

(defvar quelpa-leaf-keyword :quelpa)

;;;; Utility functions

(defun quelpa-leaf-insert-list-before (lst belm targetlst)
  "Insert TARGETLST before BELM in LST."
  (declare (indent 2))
  (let ((retlst) (frg))
    (dolist (elm lst)
      (if (eq elm belm)
          (setq frg t
                retlst (append `(,belm ,@(reverse targetlst)) retlst))
        (setq retlst (cons elm retlst))))
    (unless frg (warn "%s is not found in given list" belm))
    (nreverse retlst)))

;;; custom variable setters

(defvar quelpa-leaf-init-frg nil)

(defun quelpa-leaf-set-keywords (sym val)
  "Set SYM as VAL and modify `leaf-keywords'."
  (set-default sym val)
  (when quelpa-leaf-init-frg (quelpa-leaf-init)))

(defun quelpa-leaf-set-normalize (sym val)
  "Set SYM as VAL and modify `leaf-normalize'."
  (set-default sym val)
  (when quelpa-leaf-init-frg (quelpa-leaf-init)))

;;; implementation

(defcustom quelpa-leaf-normalize
  '(((memq leaf--key '(:quelpa))
     ;; Accept: 'nil, 't, name, recipe
     ;; Return: symbol list
     (mapcar
      (lambda (elm)
        (let ((arg (car leaf--value)))
          (pcase arg
            ((or `nil `t) (list elm))
            ((pred symbolp) leaf--value)
            ((pred listp) (cond
                           ((listp (car arg)) arg)
                           ((string-match "^:" (symbol-name (car arg))) (cons elm arg))
                           ((symbolp (car arg)) leaf--value)))
            (_ nil))))
      (delete-dups (delq nil (leaf-flatten leaf--value))))))
  "Additional `leaf-normalize'."
  :set #'quelpa-leaf-set-normalize
  :type 'sexp
  :group 'quelpa-leaf)

(defcustom quelpa-leaf-after-conditions
  (leaf-list
   :quelpa (when leaf--value
             (let ((args (car leaf--value)))
               (message "leaf--value: %s" leaf--value)
               (message "args: %s" args)
               (unless (package-installed-p ',(pcase (car args)
                                                ((pred symbolp) (car args))
                                                ((pred listp) (car (car args)))))
                 `(,@(apply 'quelpa args) ,@leaf--body)))))
  "Additional `leaf-keywords' after conditional branching.
:when :unless :if ... :ensure <this place> :after"
  :set #'quelpa-leaf-set-keywords
  :type 'sexp
  :group 'quelpa-leaf)

;;;; Main initializer

(defvar quelpa-leaf-raw-keywords nil
  "Raw `quelpa-leaf' before being modified by this package.")

(defvar quelpa-leaf-raw-normalize nil
  "Raw `quelpa-leaf' before being modified by this package.")

;;;###autoload
(defun quelpa-leaf-init (&optional renew)
  "Add additional keywords to `leaf'.
If RENEW is non-nil, renew leaf-{keywords, normalize} cache."
  (setq quelpa-leaf-init-frg t)

  (when renew
    (setq quelpa-leaf-raw-keywords nil)
    (setq quelpa-leaf-raw-normalize nil))

  (unless quelpa-leaf-raw-keywords (setq quelpa-leaf-raw-keywords leaf-keywords))
  (unless quelpa-leaf-raw-normalize (setq quelpa-leaf-raw-normalize leaf-normalize))

  ;; restore raw `leaf-keywords'
  (setq leaf-keywords quelpa-leaf-raw-keywords)
  (setq leaf-normalize quelpa-leaf-raw-normalize)

  ;; :when :unless :if :ensure <this place> :after
  (setq leaf-keywords
        (quelpa-leaf-insert-list-before leaf-keywords :after quelpa-leaf-after-conditions))

  ;; add additional normalize on the top
  (setq leaf-normalize (append quelpa-leaf-normalize quelpa-leaf-raw-normalize))

  ;; define new leaf-expand-* variable
  (eval
   `(progn
      ,@(mapcar
         (lambda (elm)
           (let ((keyname (substring (symbol-name elm) 1)))
             `(defcustom ,(intern (format "leaf-expand-%s" keyname)) t
                ,(format "If nil, do not expand values for :%s." keyname)
                :type 'boolean
                :group 'leaf)))
         (leaf-plist-keys leaf-keywords))))

  ;; require all dependent packages
  (dolist (pkg quelpa-leaf-packages-list)
    (require pkg nil 'no-error)))

(provide 'quelpa-leaf)
;;; quelpa-leaf.el ends here
