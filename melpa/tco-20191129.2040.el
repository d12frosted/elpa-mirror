;;; tco.el --- Tail-call optimisation for Emacs lisp -*- lexical-binding: t -*-

;; Copyright (C) 2013, 2016, 2017, 2019 Wilfred Hughes

;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Version: 0.3
;; URL: https://github.com/Wilfred/tco.el
;; Package-Requires: ((dash "1.2.0") (emacs "24.3"))

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
;; tco.el provides tail-call optimisation for functions in elisp that
;; call themselves in tail-position.

;; It works by replacing each self-call with a thunk, and wrapping the
;; function body in a loop that repeatedly evaluates the thunk.  Roughly
;; speaking, a function `foo':

;; (defun-tco foo (...)
;;   (...)
;;   (foo (...)))

;; Is rewritten as follows:

;; (defun foo (...)
;;    (cl-flet (foo-thunk (...)
;;                (...)
;;                (lambda () (foo-thunk (...))))
;;      (let ((result-sym (apply foo-thunk (...))))
;;        (while (is-trampoline-result-p result-sym)
;;          (setq result-sym (funcall (unwrap result-sym))))
;;        result-sym)))

;;; Code:

(require 'dash)
(eval-when-compile (require 'cl-lib))

(defun tco--add-trampoline (fun-name new-name form sentinel-sym)
  "Given quoted source FORM, replace calls to FUN-NAME (a symbol)
with a lambda expression that returns the result-sym of the FUN-NAME call."
  (--map
   (cond
    ((eq (car-safe it) fun-name)
     `(cons ',sentinel-sym
            (lambda () (,new-name ,@(cdr it)))))
    ((consp it)
     (tco--add-trampoline fun-name new-name it sentinel-sym))
    (t
     it))
   form))

;; todo: error if not in tail position
;; todo: macro-expand function body first
;; todo: preserve function arity to improve byte-compiler warnings
(defmacro defun-tco (function-name args &optional docstring &rest body)
  "Defines a function FUNCTION-NAME with self-tail-call optimisation.
BODY must contain calls to FUNCTION-NAME in the tail position."
  (declare (doc-string 3) (indent 2))
  (let* ((name (make-symbol "trampolined-function"))
         (sentinel-sym (make-symbol "tco-sentinel-symbol"))
         (trampolined
          (tco--add-trampoline
           function-name name body sentinel-sym))
         (fun-args (make-symbol "outer-fun-args"))
         (result-sym (make-symbol "trampolined-result")))
    `(defun ,function-name (&rest ,fun-args)
       ,docstring
       (cl-letf (((symbol-function ',name)
                  (lambda ,args ,@trampolined)))
         (let ((,result-sym (apply #',name ,fun-args)))
           (while (eq (car-safe ,result-sym) ',sentinel-sym)
             (setq ,result-sym (funcall (cdr ,result-sym))))
           ,result-sym)))))

;; style defun-tco like defun
(font-lock-add-keywords
 'emacs-lisp-mode
 `((,(rx
      symbol-start "defun-tco" symbol-end
      (1+ space)
      (group symbol-start
             (+ (or (syntax word) (syntax symbol)))
             symbol-end))
    (1 font-lock-function-name-face nil t))))

(provide 'tco)
;;; tco.el ends here

