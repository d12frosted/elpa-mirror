;;; letcheck.el --- Check the erroneous assignments in let forms

;; Copyright (C) 2013 Matus Goljer

;; Author: Matus Goljer <matus.goljer@gmail.com>
;; Maintainer: Matus Goljer <matus.goljer@gmail.com>
;; Created: 22 Jan 2013
;; Version: 0.4
;; Package-Version: 20160202.1948
;; Package-Commit: edf188ca2f85349e971b83f164c6484264e79426
;; Keywords: convenience
;; URL: https://github.com/Fuco1/letcheck

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Toggle checking of let assignments.  If point is inside a let form,
;; the variables in this let block are checked and if you reference a
;; previously defined variable in this let binding, it is highlight
;; with warning face, because you can't reference it.  You then need
;; to change the let into let*.

;; See github readme at https://github.com/Fuco1/letcheck

;;; Code:

(require 'thingatpt)

(defvar letcheck-overlays-list nil
  "List of overlays used to highlight erroneous assignments inside let.")

(defvar letcheck-idle-timer nil
  "Timer used to run the letcheck function.")

(defun letcheck-get-let-form ()
  "Return the let form the point is currently inside of."
  (let ((ok t) s sexp)
    (while (and ok (setq s (syntax-ppss)))
      (if (= 0 (car s))
          (setq ok nil)
        (goto-char (cadr s))
        (setq sexp (sexp-at-point))
        (when (and (listp sexp)
                   (eq (car sexp) 'let))
          (setq ok nil))))
    (when (and (listp sexp)
               (eq (car sexp) 'let))
      `(,@sexp))))

(defun letcheck-extract-variables (varlist)
  "Extract the variable names from VARLIST.
VARLIST is a list of the same format `let' accept as first
argument."
  (when (listp varlist)
    (let (vars)
      (while varlist
        (let ((current (car varlist)))
          (pop varlist)
          (if (listp current)
              (push (car current) vars)
            (push current vars))))
      (nreverse vars))))

(defun letcheck-check-variable-form (var banned-symbols)
  "Check form of variable VAR for erroneous references.
The list BANNED-SYMBOLS contains the list of symbols that are
invalid references."
  (cond
   ((listp var)
    (cons t (mapcar
             (lambda (x) (letcheck-check-variable-form x banned-symbols))
             (cdr var))))
   ((symbolp var)
    (not (memq var banned-symbols)))
   (t t)))

(defun letcheck--next-sexp ()
  "Move to the front of the next expression."
  (ignore-errors
    (forward-sexp 2)
    (backward-sexp)))

(defun letcheck-traverse-var-body (var parse)
  "Put overlays on invalid references in this let form.

Traverse the VAR body using navigation functions and mark
corresponding symbols if they have nil in the PARSE structure."
  (cond
   ((and (listp var)
         (eq var nil))
    (letcheck--next-sexp))
   ((and (listp var)
         (eq (car var) 'quote))
    (letcheck--next-sexp))
   ((and (listp var)
         (eq (car var) 'let))
    (letcheck--next-sexp))
   ((listp var)
    (down-list)
    (let ((p parse))
      (dolist (x var)
        (letcheck-traverse-var-body x (car p))
        (setq p (cdr p))))
    (up-list)
    (ignore-errors (forward-sexp) (backward-sexp)))
   ((symbolp var)
    (if (not parse)
        (let ((ov (make-overlay
                   (save-excursion (forward-sexp) (backward-sexp) (point))
                   (progn (forward-sexp) (point)))))
          (push ov letcheck-overlays-list)
          (overlay-put ov 'face font-lock-warning-face)
          (ignore-errors (forward-sexp) (backward-sexp)))
      (letcheck--next-sexp)))
   (t (letcheck--next-sexp))))

(defun letcheck-function ()
  "Test if point is inside let form."
  ;; remove any overlay that has letcheck property
  (when letcheck-mode
    (dolist (ov letcheck-overlays-list) (delete-overlay ov))
    (setq letcheck-overlays-list nil)
    (save-excursion
      (let* ((let-form (letcheck-get-let-form))
             (varlist (and let-form (cadr let-form)))
             (variables (and let-form (letcheck-extract-variables varlist)))
             cvars)
        (when variables
          (down-list 2)
          (letcheck--next-sexp)
          (pop varlist) ;; the first variable is always correct!
          (push (pop variables) cvars)
          (while varlist
            (push (pop variables) cvars)
            (let ((thing (sexp-at-point)))
              (cond
               ((listp thing)
                (letcheck-traverse-var-body
                 thing
                 (letcheck-check-variable-form (car varlist) cvars)))
               (t (letcheck--next-sexp))))
            (pop varlist)))))))

;;;###autoload
(define-minor-mode letcheck-mode
  "Toggle checking of let assignments.
If point is inside a let form, the variables in this let block
are checked and if previously defined variable in this let
binding is referenced, it is highlighted with warning face.  This
is because it is not possible to reference local variables in let
form in Emacs LISP.  This will guide the user to spot this kind
of error and advice her to change the let into let*."
  :init-value nil
  (if letcheck-mode
      (unless letcheck-idle-timer
        (setq letcheck-idle-timer
              (run-with-idle-timer 0.125 t
                                   'letcheck-function)))
    (when letcheck-idle-timer
      (cancel-timer letcheck-idle-timer)
      (setq letcheck-idle-timer nil))
    (when letcheck-overlays-list
      (dolist (ov letcheck-overlays-list) (delete-overlay ov)))))

(provide 'letcheck)

;;; letcheck.el ends here
