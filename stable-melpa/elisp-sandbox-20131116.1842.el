;;; elisp-sandbox.el --- Evaluate EmacsLisp expressions in a sandbox

;; Copyright (C) 2002 D. Goel, 2012, 2013 Joel McCracken
;; Author: Joel McCracken <mccracken.joel@gmail.com>, D. Goel <deego@gnufans.org>
;; Version: 0.0.1
;; URL: https://github.com/joelmccracken/elisp-sandbox
;; Keywords: lisp

;; This file is NOT (yet) part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; this file is adapted from the code from erbot. see:

;; http://www.emacswiki.org/cgi-bin/wiki.pl?ErBot

;; eventually I hope to make it better, but for now
;; other projects can use the same sandboxing functionality

(defconst elisp-sandbox-prefix "elisp-sandbox-unsafe-env-"
  "The prefix for symbols that are to be exposed to a sandbox
environment.")

(defvar sandbox-allowed-words
  '(nil
    t
    ;; Also consider:
    &rest
    &optional
    )
  "You should add &rest and &optional to this list.
We WON'T do this by default since this could lead to exploits if you
*happen* to have bound these keywords to weird stuff like
\(setq &rest (shell-command \"rm -rf /\")) in your .emacs."
  )

;; main entry point is elisp-sandbox
;; sandbox takes an expression and makes sure it is okay to evaluate

(defun elisp-sandbox (expr)
  "sandboxes an expression to prevent it accessing unwhitelisted functionality"
  (cond
   ;; first condition
   ((null expr) nil)
   ;; second condition
   ((listp expr)
    (when (sandbox--check-args expr)
      (let ((fir (first expr)))
        (cond
         ((listp fir)
          (cons (sandbox fir)
                (mapcar 'sandbox (cdr expr))))
         ((equal (format "%S" fir) "quote")
          ;; if quoted, it is fine...
          expr)
         (t (cons
             (if (or (equal 0 (string-match elisp-sandbox-prefix (format "%S" fir)))
                     (member fir sandbox-allowed-words))
                 fir
               ;; todo: bind this to its original name
               (intern (concat elisp-sandbox-prefix (format "%S" fir))))
             (mapcar 'sandbox (cdr expr))))))))

   ;; final condition.. --> when the expr is an atom..  It should be a
   ;; a constant..  or an allowed atom.. allowed == prefixed with fs-
   (t (cond
       ((and (symbolp expr)
             (equal 0 (string-match elisp-sandbox-prefix (format "%s" expr))))
        expr)
       ((equal expr t) expr)
       ((member expr sandbox-allowed-words) expr)
       ((symbolp expr)
        ;;(boundp (intern (concat elisp-sandbox-prefix (format "%S" expr)))))
        (intern (concat elisp-sandbox-prefix (format "%s" expr))))
       ;; other symbol
       ;;((symbolp expr) (list 'quote expr))
       ;; a number or string now..
       ;; this actually happens when they feed byte-compiled code to
       ;; the bot, like:
       ;;, (funcall #[nil "\300\207" [1] 1])
       ((not (or (symbolp expr) (numberp expr) (stringp expr)))
        (error "%s %s" "Should not reach here.  Quantum Tunnelling! "
               "What are you trying to feed me? Byte-compiled code? Vectors?"  ))
       (t expr)))
   ))

(defalias 'sandbox 'elisp-sandbox)


(defun elisp-sandbox-eval (form)
  (setq elisp-sandbox-evaluation-output nil)
  (eval `(progn ,(elisp-sandbox form))))


;; integrating erbot's sandbox functions
(defvar sandbox-while-ctr 0)
(defvar sandbox-while-max 10000)

(defmacro elisp-sandbox-unsafe-env-while (cond &rest body)
  `(let
       ((sandbox-while-ctr 0))
     (while
         ,cond
       ;; this should enable the with-timeout checks..
       ;; (sleep-for 0.01)
       (if (> sandbox-while-ctr sandbox-while-max)
           (error "Max while iterations exceeded: %S"
                  sandbox-while-ctr))
       (incf sandbox-while-ctr)
       nil
       ,@body)))

(defun sandbox-constant-object-p (object)
  "If the object is a symbol like nil or t, a symbol that cannot be
redefunned, return true. "
  (or (member object (list nil t))
      (keywordp object)))

(defun sandbox-readonly-check (sym)
  (if (get sym 'readonly)
      (error "The symbol %S can't be redefined or set! It is read-only!"
             sym)))

(defun sandbox-create-defun-overwrite (sexps body fcn)
  (cons body
        (remove
         (first (member-if
                 (lambda (arg) (equal (second arg) fcn))
                 sexps))
         sexps)))




(defun elisp-sandbox-prefix-unless-prefixed (symbol &optional do-intern)
  "ensures that symbol has the given elisp-sandbox prefix.
If it doesn't, prefix is added."
  (let ((symbol-create-fn
         (if do-intern
             (symbol-function 'intern)
           (symbol-function 'make-symbol))))
    (if (equal 0 (string-match elisp-sandbox-prefix (format "%s" symbol)))
        symbol
      (funcall symbol-create-fn (concat elisp-sandbox-prefix (format "%s" symbol))))))


(defmacro sandbox-defun (name args &rest body)
  (declare (indent defun))
  `(defun ,(intern (concat elisp-sandbox-prefix (symbol-name name)))
     ,args
     ,@body))

(defvar elisp-sandbox-evaluation-output nil
  "List that contains the output from the previous sandbox evaluation")

(sandbox-defun message (msg)
  (push msg elisp-sandbox-evaluation-output)
  )
(defvar sandbox-max-list-length 100)

(defmacro sandbox--check-args (&rest args)
  "All we do in this macro we remove some bindings for things like
&rest, etc, things that do not have values but got passed to us --
this occurs when a user attempts to use &rest in his function
definitions -- see `sandbox-allowed-words'.

All the arguments to this macro should have been in their evalled form
and hence constants already, so we do not bother protecting against
multiple evaluations here -- evaluating a constant causes no harm.
All we do in this macro we remove some bindings for things like &rest,
etc, things that are not defined, but passed on here in any case."
  `(sandbox--check-args-nascent
    ,@(remove-if
       #'(lambda (arg) (and
                   (symbolp arg)
                   (not (boundp arg))))
       args)))

(defun sandbox--check-args-nascent (&rest args)
  (if (or
       (not (numberp sandbox-max-list-length))
       (sandbox--safe-length-args-p args 0 sandbox-max-list-length))
      t
    (error "encountered overlong expression, ignoring") nil))


(defun sandbox--safe-length-args-p (list so-far len)
  (let ((cur list)
        stack)
    (while (and cur
                (<= so-far len))
      (if (consp (car cur))
          (progn (setq cur (car cur))
                 (when (consp (cdr cur))
                   (push (cdr cur) stack)))
        (setq cur (cdr cur)))
      (unless cur
        (setq cur (pop stack)))
      (setq so-far (1+ so-far)))
    (if (<= so-far len)
        t
      nil)))


(defalias 'elisp-sandbox-progn 'progn)


(defun elisp-sandbox-readonly-check (sym)
  (if (get sym 'readonly)
      (error "The symbol %S can't be redefined or set! It is read-only!"
       sym)))


(defmacro elisp-sandbox-defun (fcn args &rest body)
  ;; the given fcn icould be a number or string, in which
  ;; case sandboxing won't touch it, so we need to override that case.
  (let* ((docp nil)
        (fcn-name (symbol-name fcn))
        (fcn (cond
              ((or (numberp fcn) (stringp fcn)) fcn)
              ((equal 0 (string-match elisp-sandbox-prefix fcn-name))
               fcn)
              (t (intern (concat elisp-sandbox-prefix fcn-name))))))
    (unless
        (and (listp body)
             (> (length body) 0))
      (error "Function body should have a length of 1 or more"))
    (unless (and (symbolp fcn) (not (elisp-sandbox-constant-object-p fcn)))
      (error "Defun symbols only! :P"))
    ;; doc string exists, and is followed by more stuff..
    (when (and (> (length body) 1)
               (stringp (first body)))
      (setq docp t))
    (elisp-sandbox-readonly-check fcn)
    ;; not actually sure why
    (let ((code-with-sit-for
           (if docp
               (cons 'defun
                     (cons fcn
                           (cons args
                                 (cons
                                  (first body)
                                  (cons
                                   `(sandbox--check-args ,@args)
                                   (cons
                                    '(sit-for 0)
                                    (cdr body)))))))
             (cons 'defun
                   (cons fcn
                         (cons args
                               (cons
                                `(sandbox--check-args ,@args)
                                (cons
                                 '(sit-for 0)
                                 body))))))

           ))
      (eval code-with-sit-for))
    `(quote ,fcn)))


(defalias 'elisp-sandbox-unsafe-env-defun 'elisp-sandbox-defun)

(defun elisp-sandbox-constant-object-p (object)
  "If the object is a symbol like nil or t, a symbol that cannot be
redefunned, return true. "
  (or (member object (list nil t))
      (keywordp object)))


(defalias 'elisp-sandbox-setf 'setf)


(defun elisp-sandbox-import-alias (original)
  "alias a function with env prefix"
  (defalias (elisp-sandbox-prefix-unless-prefixed original t) original))

(elisp-sandbox-import-alias '+)
(elisp-sandbox-import-alias '<)
(elisp-sandbox-import-alias 'progn)
(elisp-sandbox-import-alias 'setq)
(elisp-sandbox-import-alias 'let)
(elisp-sandbox-import-alias 'ignore-errors)
(elisp-sandbox-import-alias 'if)

(provide 'elisp-sandbox)

;;; elisp-sandbox.el ends here
