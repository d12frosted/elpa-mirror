;;; mmt.el --- Missing macro tools for Emacs Lisp -*- lexical-binding: t; -*-
;;
;; Copyright © 2015–present Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/mrkkrp/mmt
;; Package-Version: 20210321.1829
;; Package-Commit: e5cd2b4d0967758471fd2753f78120bdeb93a781
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.5") (cl-lib "0.3"))
;; Keywords: macro, emacs-lisp
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The following functions and macros are present:
;;
;; * mmt-make-gensym-list
;; * mmt-with-gensyms
;; * mmt-with-unique-names
;; * mmt-once-only

;;; Code:

(eval-when-compile (require 'cl-lib))

(defun mmt-make-gensym-list (length &optional x)
  "Return a list of LENGTH gensyms.

Each element of the list is generated as if with a call to
`cl-gensym' using the second argument X (defaulting to \"G\")."
  (mapcar #'cl-gensym (make-list length (or x "G"))))

(defmacro mmt-with-gensyms (names &rest body)
  "Bind each variable in NAMES to a unique symbol and evaluate BODY.

Each element of NAMES must be either a symbol, or of the form:

  (SYMBOL STRING-OR-SYMBOL)

Bare symbols appearing in NAMES are equivalent to:

  (SYMBOL SYMBOL)

The STRING-OR-SYMBOL is used (converted to a string if necessary)
as the argument to `cl-gensym' when constructing the unique
symbol the named variable will be bound to."
  (declare (indent 1))
  `(let ,(mapcar (lambda (name)
                   (cl-destructuring-bind (symbol . prefix)
                       (if (consp name)
                           (cons (car name) (cadr name))
                         (cons name name))
                     `(,symbol
                       (cl-gensym
                        ,(if (symbolp prefix)
                             (symbol-name prefix)
                           prefix)))))
                 names)
     ,@body))

(defalias 'mmt-with-unique-names 'mmt-with-gensyms)

(defmacro mmt-once-only (specs &rest body)
  "Rebind symbols according to SPECS and evaluate BODY.

Each element of SPECS must be either a symbol naming the variable
to be rebound or of the form:

  (SYMBOL INITFORM)

where INITFORM is guaranteed to be evaluated only once.

Bare symbols in SPECS are equivalent to

  (SYMBOL SYMBOL)

Example:

  (defmacro cons1 (x) (mmt-once-only (x) `(cons ,x ,x)))
  (let ((y 0)) (cons1 (incf y))) => (1 . 1)"
  (declare (indent 1))
  (let* ((gensyms (mmt-make-gensym-list (length specs) "ONCE-ONLY"))
         (names-and-forms
          (mapcar (lambda (spec)
                    (if (consp spec)
                        (cl-destructuring-bind (name form) spec
                          (cons name form))
                      (cons spec spec)))
                  specs))
         (names (mapcar #'car names-and-forms))
         (forms (mapcar #'cdr names-and-forms)))
    ;; DANGER! Brain-damaging code follows:
    `(mmt-with-gensyms ,(cl-mapcar #'list gensyms names)
       (list 'let
             (cl-mapcar #'list (list ,@gensyms) (list ,@forms))
             ,(cl-list* 'let
                        (cl-mapcar #'list names gensyms)
                        body)))))

(provide 'mmt)

;;; mmt.el ends here
