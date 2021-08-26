;;; debug-print.el --- A nice printf debugging environment by the way Gauche do -*- lexical-binding: t -*-

;; Copyright (C) 2013  Ken Okada

;; Author: Ken Okada <keno.ss57@gmail.com>
;; Keywords: extensions, lisp, tools, maint
;; URL: https://github.com/kenoss/debug-print
;; Package-Requires: ((emacs "24"))

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

;; This program provides a nice ``printf debugging'' environment by
;; the way Gauche do. Sometimes printf debugging with `message' bothers you.
;; For example, if you want to observe the variable `foo' in the expression
;;   (let ((foo (something-with-side-effect)
;;         (bar (something-depends-on foo))
;;     ...)
;; you have to use frustrating idiom:
;;   (let ((foo (progn
;;                (let ((tmp (something-with-side-effect)))
;;                  (message "%s" tmp)
;;                  tmp)))
;;         (bar (something-depends-on foo))
;;     ...)
;; (In this case one can use `let*' but it is an example.) This program
;; allows you to write as follows:
;;   (let ((foo ::?= (something-with-side-effect)
;;         (bar (something-depends-oidn foo))
;;     ...)
;; After rewrite, move point to the last of expression as usual, and do
;; `debug-print-eval-last-sexp'. It is the same as `eval-last-sexp' except rewrite
;; the read expression recursively as follows:
;;   ... ::?= expr ...
;;     => ... (debug-print expr) ...
;; Here `debug-print' is a macro, which does that the above frustrating idiom does.
;; (Note that this needs initialization.) For who kwons Gauche note that it is
;; not implemented by reader macro. So one have to use some settings to inform
;; emacs that the expression needs preprocessed.
;;
;; Initialization and configuration: To use the above feature, write as follows
;; in your .emacs.d/init.el (after setting of load-path):
;;   (require 'debug-print)
;;   (debug-print-init)
;;   (define-key global-map (kbd "C-x C-e") 'debug-print-eval-last-sexp)
;; debug-print.el use some variables:
;;   `debug-print-symbol'
;;   `debug-print-buffer-name'
;;   `debug-print-width'
;; (See definitions below.) You have to set these before calling of `debug-print-init'.
;;
;; Example of code:
;;   (debug-print-init)
;;   (eval-with-debug-print
;;    (defun fact (n)
;;      (if (zerop n)
;;          1
;;          (* n ::?= (fact (- n 1))))))
;;   (fact 5)
;; Result: <buffer *debug-print*>
;;   ::?="fact"::(fact (- n 1))
;;   ::?="fact"::(fact (- n 1))
;;   ::?="fact"::(fact (- n 1))
;;   ::?="fact"::(fact (- n 1))
;;   ::?="fact"::(fact (- n 1))
;;   ::?-    1
;;   ::?-    1
;;   ::?-    2
;;   ::?-    6
;;   ::?-    24
;; For more detail, see debug-print-test.el .

;;; Code:


;; move to keu
(when (not (featurep 'k-emacs-utils))
  (defsubst keu:advice-enabled-p (func class name)
    "[internal] Return t (resp. nil) if advice NAME of FUNC is enabled (resp. disabled)."
    (not (not (ad-advice-enabled (ad-find-advice func class name)))))

  (defmacro keu:with-advice (enable-or-disable func class name &rest body)
    "[internal] Evaluate BODY with NAME enabled/disabled."
    (declare (indent 4))
    (let ((enabled
           (pcase enable-or-disable
             (`'enable t)
             (`'disable nil)
             (_ (error "the first argument must be the symol 'enable or 'disable")))))
      `(if (eq ,enabled (keu:advice-enabled-p ,func ,class ,name))
           (progn ,@body)
           (prog2                       ; return value is that of BODY
               (progn
                 (,(if enabled 'ad-enable-advice 'ad-disable-advice) ,func ,class ,name)
                 (ad-activate ,func))
               (progn ,@body)
             (progn
               (,(if (not enabled) 'ad-enable-advice 'ad-disable-advice) ,func ,class ,name)
               (ad-activate ,func))))))

  (if (featurep 'srfi)
      (defalias 'keu:reverse 'srfi:reverse)
      (defun keu:reverse (xs &optional ys)
        "Imported from Gauche."
        (dolist (x xs ys) (push x ys))))

  (defun keu:replace-in-tree (bindings sexp)
    "Like `sublis', return a copy of SEXP with all matching elements replaced.
BINDINGS should be a list and its elements should be the followings:

  (VAR VAL)   : VAR in SEXP are replaced with VAL.
  (VAR @ VAL) : Like the above except that VAL are spliced.

Note that VAL is not evaluated.

Examples:
  (keu:replace-in-tree '((a 0)
                         (c @ ())
                         (e @ (+ 1 2))
                         (g @))
                       '(a b c d e f g))
  ; => (0 b d + 1 2 f @)

  (keu:replace-in-tree '((a 0)
                         (c @ ())
                         (e @ (+ 1 2)))
                       '(a (a b c d e) c ((a) b (c) d (e)) e))
  ; => (0
  ;     (0 b d + 1 2)
  ;     ((0)
  ;      b nil d
  ;      (+ 1 2))
  ;     + 1 2)"
    (let ((bindings (mapcar (lambda (bind)
                              (if (and (eq '\@ (cadr bind)) (not (null (cddr bind))))
                                  (list (car bind) t (caddr bind))
                                  (list (car bind) nil (cadr bind))))
                            bindings)))
      (keu:replace-in-tree:iter bindings sexp nil nil nil)))
  (defsubst keu:replace-in-tree:atom (bindings a non-splicing-case &optional splicing-case)
    (catch 'return
      (dolist (bind bindings (funcall non-splicing-case a))
        (when (eq a (car bind))
          (throw 'return
                 ;; (if (eq '\@ (cadr bind))
                 ;;     (funcall (or splicing-case non-splicing-case) (caddr bind))
                 ;;     (funcall non-splicing-case (cadr bind))))))))
                 (if (cadr bind)
                     (funcall (or splicing-case non-splicing-case) (caddr bind))
                     (funcall non-splicing-case (caddr bind))))))))
  ;; `cut' was replaced manually
  (defun keu:replace-in-tree:iter (bindings sexp acc l-stack r-stack)
    (cond ((atom sexp)
           (if (null l-stack)             ; <=> (null r-stack)
               (keu:replace-in-tree:atom bindings sexp (lambda (x) (keu:reverse acc x)))
               (keu:replace-in-tree:iter bindings
                                      (car r-stack)
                                      (cons (keu:replace-in-tree:atom bindings sexp (lambda (x) (keu:reverse acc x)))
                                            (car l-stack))
                                      (cdr l-stack)
                                      (cdr r-stack))))
          ((consp (car sexp))
           (keu:replace-in-tree:iter bindings (car sexp) nil (cons acc l-stack) (cons (cdr sexp) r-stack)))
          (t
           (keu:replace-in-tree:iter bindings (cdr sexp)
                                  (keu:replace-in-tree:atom bindings (car sexp)
                                                         (lambda (x) (cons x acc))
                                                         (lambda (x) (keu:reverse x acc)))
                                  l-stack r-stack))))
  )



(eval-when-compile (require 'advice))
(require 'cl-lib)
(require 'cl) ; only for caddr



;;; configuration

(defvar debug-print-symbol ::?=)
(defvar debug-print-buffer-name "*debug-print*")
(defvar debug-print-width 30)



;;; core

(defmacro debug-print (expr &optional f-name)
  "[internal] Evaluate EXPR, display and return the result. The results are
displayed in the buffer with buffer name `debug-print-buffer-name'. The
optional argument F-NAME indicates in what function EXPR is."
  `(with-current-buffer debug-print-buffer
     (progn
       (goto-char (point-max))
       (insert (format debug-print-format-for-::?= ,(or f-name "") "" ',expr))
       (let ((value ,expr))
         (progn
           (insert (format debug-print-format-for-::?- value))
           value)))))

(defun debug-print:code-walk (sexp f-name)
  "[internal] Replaces the symbol `debug-print-symbol' (default is ::?=) followed
by EXPR in SEXP with (debug-print EXPR). If possible it detects in what function
EXPR is, and inform `debug-print' of that."
  (let ((sexp (if (memq (car-safe sexp) '(defadvice lambda))
                  sexp
                  (macroexpand sexp))))
    (pcase sexp
      (`()
       '())
      (`(quote ,x)
       `(quote ,(debug-print:code-walk x f-name)))
      (`(\` ,x)
       `(\` ,(debug-print:code-walk x f-name)))
      (`(,(pred (eq debug-print-symbol)) ,x . ,rest)
       `((debug-print ,(debug-print:code-walk x f-name) ,f-name)
         ,@(debug-print:code-walk rest f-name)))
      (`(defun ,name ,args . ,rest)
       `(defun ,name ,args ,@(debug-print:code-walk rest (symbol-name name))))
      (`(defmacro ,name ,args . ,rest)
       `(defmacro ,name ,args ,@(debug-print:code-walk rest (symbol-name name))))
      (`(,x . ,rest)
       `(,(debug-print:code-walk x f-name) ,@(debug-print:code-walk rest f-name)))
      (x
       x))))

(defmacro eval-with-debug-print (expr)
  "Evaluate EXPR with debug print. See also `debug-print:code-walk'."
  (debug-print:code-walk expr nil))
(defmacro eval-without-debug-print (expr)
  (keu:replace-in-tree `((,debug-print-symbol @ ())) expr))



;;; user interface

(defun debug-print-eval-last-sexp ()
  "Evaluate last sexp with debug print. See aslo `debug-print:code-walk'."
  (interactive)
  (keu:with-advice 'enable 'preceding-sexp 'after 'debug-print-hijack-emacs-ad
    (call-interactively 'eval-last-sexp)))
(defadvice preceding-sexp (after debug-print-hijack-emacs-ad disable)
  "Enclose sexp with `eval-with-debug-print'."
  (setq ad-return-value `(eval-with-debug-print ,ad-return-value)))

(defun debug-print-init ()
  "Initialize some variables for `debug-print'. Note that custamizable variables
have to be set before calling of this funciton."
  (interactive)
  (progn
    (setq debug-print-format-for-::?=
          (concat "::?=\"%s\":%s:%-" (int-to-string debug-print-width) "s\n"))
    (setq debug-print-format-for-::?-
          (concat "::?-    %-" (int-to-string debug-print-width) "s\n"))
    (setq debug-print-buffer (get-buffer-create debug-print-buffer-name))))



(provide 'debug-print)
;;; debug-print.el ends here
