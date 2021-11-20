;;; iter2.el --- Reimplementation of Elisp generators  -*- lexical-binding: t -*-

;;; Copyright (C) 2017-2021 Paul Pogonyshev

;; Author:     Paul Pogonyshev <pogonyshev@gmail.com>
;; Maintainer: Paul Pogonyshev <pogonyshev@gmail.com>
;; Version:    1.1
;; Package-Version: 20211119.1718
;; Package-Commit: 077684feec98ce6d5e283a13f056c083986628a2
;; Keywords:   elisp, extensions
;; Homepage:   https://github.com/doublep/iter2
;; Package-Requires: ((emacs "25.1"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see http://www.gnu.org/licenses.


;;; Commentary:

;; Fully compatible fast reimplementation of `generator' built-in
;; Emacs package.  This library provides `iter2-defun` and
;; `iter2-lambda` forms that can be used in place of `iter-defun` and
;; `iter-lambda`.  All other functions and macros (e.g. `iter-yield`,
;; `iter-next`) are intentionally not duplicated: just use the
;; original ones.


;;; Code:

;; For `iter-yield' etc. from the original `generator' package.
(require 'generator)
(require 'macroexp)
(require 'subr-x)


(defgroup iter2 nil
  "Reimplementation of Elisp generators"
  :group 'lisp)

(defcustom iter2-detect-nested-lambda-yields nil
  "If non-nil, detect non-working yields in nested lambdas.
Due to the way `iter2' (or original `generator', for that matter)
works, it is impossible to yield from nested lambdas: only from
the main function.  Such `iter-yield' invocations will fail at
runtime.

When this variable is set, `iter2' tries to detect such problems
during conversion.  However, this test is not enabled by default
because it might, in principle, give false positives if you never
call said lambda.  It also negatively affects performance.

On the other hand, this might be useful, as it is very easy to
accidentally try to yield from a macro-generated lambda, e.g.:

    # Replace each element with what `iter-yield' returns.  Not
    # obvious that this form will not work.
    (setf list (--map (iter-yield it) list))"
  :type  'boolean
  :group 'iter2)


(defvar iter2-generate-tracing-functions nil
  "Set to non-nil to always generate tracing functions.
Normally, only `iter2-tracing-defun' and `iter2-tracing-lambda'
will do this.  But if this flag is set, `iter2-defun' and
`iter2-lambda' will behave similarly.")

(defvar iter2-tracing-print-level t
  "Value used for `print-level' when tracing generator functions.
If set to t, value of `print-level' at the time of tracing is
preserved.  Otherwise, it is overwritten with the value of this
variable.")

(defvar iter2-tracing-print-length t
  "Value used for `print-length' when tracing generator functions.
If set to t, value of `print-length' at the time of tracing is
preserved.  Otherwise, it is overwritten with the value of this
variable.")

(defvar iter2-tracing-function #'iter2-log-message
  "Function called to trace iterator execution.
The function must accept the same arguments as built-in
`message', but is not restricted in what it does with the
messages.  If the value is nil, tracing is disabled even for
iterator functions that are supposed to trace.")


(defvar iter2--tracing-depth 0)

(defvar iter2--value           nil)
(defvar iter2--continuations   nil)
(defvar iter2--cleanups        nil)
(defvar iter2--stack           nil)
(defvar iter2--yielding        nil)
(defvar iter2--done            nil)
(defvar iter2--stack-state     nil)
(defvar iter2--catcher         nil)
(defvar iter2--cleanups-used   nil)
(defvar iter2--converter-depth 0)


(defmacro iter2-defun (name arglist &rest body)
  "Create a generator function NAME.
When called, generator returns an iterator object.  Successive
values can be retrieved from an iterator using `iter-next'.

From generator perspective, BODY is executed whenever a new
iterator object is created.  At each point `iter-yield' is called
in the body, evaluation stops, and is resumed at exactly the same
point with the same state (both local and global variables) if
`iter-next' is used to query another value.

Iterator objects must be closed with `iter-close' unless they are
fully exhausted, i.e. signal `iter-end-of-sequence'.  Calling
`iter-close' on an exhausted iterator object or even several
times is not an error."
  (declare (debug defun) (indent 2) (doc-string 3))
  (let ((parsed-body (macroexp-parse-body body)))
    `(defun ,name ,arglist
       ,@(car parsed-body)
       ,(iter2--convert-function-body (cdr parsed-body) iter2-generate-tracing-functions))))

(defmacro iter2-lambda (arglist &rest body)
  "Create an anonymous generator function.
See `iter2-defun' for details."
  (declare (debug lambda) (indent 1) (doc-string 2))
  (let ((parsed-body (macroexp-parse-body body)))
    `(lambda ,arglist
       ,@(car parsed-body)
       ,(iter2--convert-function-body (cdr parsed-body) iter2-generate-tracing-functions))))

(defmacro iter2-tracing-defun (name arglist &rest body)
  "Create a tracing generator function NAME.
See `iter2-defun' for details."
  (declare (debug defun) (indent 2) (doc-string 3))
  (let ((iter2-generate-tracing-functions t))
    (macroexpand-1 `(iter2-defun ,name ,arglist ,@body))))

(defmacro iter2-tracing-lambda (arglist &rest body)
  "Create a tracing anonymous generator function NAME.
See `iter2-defun' for details."
  (declare (debug lambda) (indent 1) (doc-string 2))
  (let ((iter2-generate-tracing-functions t))
    (macroexpand-1 `(iter2-lambda ,arglist ,@body))))

(defun iter2--literalp (x)
  "Determine if X involves no evaluation."
  (if (atom x)
      (or (not (symbolp x))
          (memq x '(nil t))
          (keywordp x))
    ;; Don't check for wrong forms here: just let it fail later in such a case.
    (memq (car x) '(quote function))))

(defun iter2--literal-or-variable-p (x)
  (or (atom x) (memq (car x) '(quote function))))

(defmacro iter2--convert-progn (forms)
  (declare (debug (form)))
  `(iter2--convert-form (macroexp-progn ,forms)))

(defmacro iter2--add-converted-form (place converted-form)
  (declare (debug (place form)))
  `(setf ,place (nconc (reverse (macroexp-unprogn ,converted-form)) ,place)))

(defmacro iter2--finish-chunk (converted-chunks converted &rest next-chunk-forms)
  (declare (debug (place place &rest form)))
  `(setf ,converted-chunks (cons (macroexp-progn (nreverse ,converted)) ,converted-chunks)
         ,converted        ,(when next-chunk-forms `(list ,@next-chunk-forms))))

(defun iter2--convert-function-body (body &optional tracing)
  (unless lexical-binding
    (error "Generator functions require lexical binding"))
  (let* ((iter2-generate-tracing-functions tracing)
         (iter2--value                     (make-symbol "$value"))
         (iter2--continuations             (make-symbol "$continuations"))
         (iter2--cleanups                  (make-symbol "$cleanups"))
         (iter2--stack                     (make-symbol "$stack"))
         (iter2--yielding                  (make-symbol "$yielding"))
         (iter2--done                      (make-symbol "$done"))
         (iter2--stack-state               (make-symbol "$stack-state"))
         (iter2--catcher                   (make-symbol "$catcher"))
         (iter2--cleanups-used             nil)
         (apply-debugger                   (lambda (&rest forms) forms)))
    (pcase body
      (`((edebug-enter ,edebug-name ,edebug-args (function (lambda () . ,real-body))))
       ;; This is a hack, but since Emacs code (Edebug in this case) is pretty stable, I'm
       ;; sure it will keep working.  The idea is to invoke `edebug-enter' not when the
       ;; function is first called (this creates and returns an iterator object and
       ;; doesn't involve user code at all), but instead when it receives control after
       ;; `iter-next' or `iter-yield' call.  This also solves the issue with form
       ;; conversion: normally `iter2--convert-form' doesn't recurse into nested lambdas.
       (setq body           real-body
             apply-debugger (lambda (&rest forms) `((edebug-enter ,edebug-name ,edebug-args (function (lambda () ,@forms))))))))
    ;; Need to convert the body now, since this affects at least `iter2--cleanups-used'.
    (let ((converted (iter2--convert-progn body)))
      `(let (,iter2--continuations
             ,@(when iter2--cleanups-used (list iter2--cleanups))
             ,iter2--stack
             ,iter2--yielding)
         ;; Must not be moved to `let' above, since the lambda accesses the other
         ;; variables declared there.
         (setq ,iter2--continuations (list (lambda (,iter2--value) ,@(macroexp-unprogn (iter2--merge-continuation-form converted)))))
         (lambda (operation value)
           (cond ((eq operation :next)
                  ,@(funcall apply-debugger
                             ;; Rewritten in a somewhat weird form to maximize performance.
                             `(while (progn (setq value ,(iter2--continuation-invocation-form 'value `(or (pop ,iter2--continuations)
                                                                                                          (signal 'iter-end-of-sequence value))))
                                            (not ,iter2--yielding)))
                             `(setq ,iter2--yielding nil)
                             `value))
                 ((eq operation :close)
                  ,@(funcall apply-debugger
                             (if iter2--cleanups-used
                                 `(let ((cleanups ,iter2--cleanups))
                                    (setq ,iter2--continuations nil
                                          ,iter2--cleanups      nil
                                          ,iter2--stack         nil)
                                    (if cleanups
                                        (iter2--do-clean-up cleanups)))
                               `(setq ,iter2--continuations nil
                                      ,iter2--stack         nil))))
                 (t (error "Unknown iterator operation %S" operation))))))))

(defsubst iter2--do-macroexpand (form)
  ;; Prevent `macroexpand' from expanding macros for which we have special handling.
  (macroexpand form '((save-match-data . nil))))

;; Returns (CONVERTED-FORM . CONTINUATION-FORM)
;;
;; if CONVERTED-FORM never yields, CONTINUATION-FORM is nil.  CONTINUATION-FORM itself
;; never yields.
;;
;; Since this function is recursive, it can certainly run out of stack
;; on complicated forms if not byte-compiled.
(defun iter2--convert-form (form)
  (if (atom form)
      ;; Speed optimizations, also simplifies debugging a bit.
      (cons form nil)
    (let ((body (macroexp-unprogn form))
          can-yield
          converted
          converted-chunks)
      (while body
        (let ((form (iter2--do-macroexpand (pop body))))
          ;; Simplify certain forms, rewrite certain others using
          ;; special forms that we handle below.
          (while (let ((rewritten-form
                        (pcase form
                          (`(and)                                        t)
                          (`(or)                                         nil)
                          (`(,(or 'and 'or) ,only-condition)             (iter2--do-macroexpand only-condition))
                          (`(cond)                                       nil)
                          (`(cond (,only-condition))                     (iter2--do-macroexpand only-condition))
                          (`(cond (,only-condition . ,body))             `(if ,only-condition ,(macroexp-progn body)))
                          (`(,(or 'let 'let*) () . ,let-body)            (setq body (append (cdr let-body) body)) (iter2--do-macroexpand (car let-body)))
                          (`(,(or 'progn 'inline))                       nil)
                          (`(,(or 'progn 'inline 'prog1) ,only-form)     (iter2--do-macroexpand only-form))
                          (`(,(or 'progn 'inline) ,first . ,others)      (setq body (append others body)) (iter2--do-macroexpand first))
                          (`(prog1 ,value . ,rest)                       (if body
                                                                             ;; This value is not going to be used anyway,
                                                                             ;; so just inline this into `body'.
                                                                             (progn (setq body (append rest body)) (iter2--do-macroexpand value))
                                                                           ;; Do nothing.
                                                                           form))
                          (`(prog2 ,first ,second . ,others)             `(prog1 (progn ,first ,second) ,@others))
                          (`(unwind-protect ,body-form)                  (iter2--do-macroexpand body-form))
                          (`(condition-case ,_ ,body-form)               (iter2--do-macroexpand body-form))
                          (_                                             form))))
                   (if (eq form rewritten-form)
                       nil
                     (setq form rewritten-form))))
          (pcase form

            ;; Handle nested lambdas; optionally check them for yields.
            (`(function (lambda ,_lambda-args . ,lambda-body))
             ;; Could write a faster function here, but probably not performance-critical.
             (when (and iter2-detect-nested-lambda-yields (cdr (iter2--convert-progn lambda-body)))
               (error "Nested anonymous function %S yields, which will fail at runtime" (cadr form)))
             (push form converted))

            ;; Handle quoting ('_ and #'_): just pass it through.
            (`(,(or 'quote 'function) ,_)
             (push form converted))

            ;; Handle (and CONDITIONS...) and (or CONDITIONS...).
            (`(,(and (or 'and 'or) operator) . ,conditions)
             (let (plain-conditions)
               (while conditions
                 (let* ((converted-condition      (iter2--convert-form (pop conditions)))
                        (converted-condition-form (car converted-condition)))
                   (if (cdr converted-condition)
                       (progn
                         (if conditions
                             (let ((converted-continuation (iter2--convert-form `(,operator ,(cdr converted-condition) ,@conditions))))
                               (setq converted-condition-form `(progn ,(iter2--continuation-adding-form (list (iter2--merge-continuation-form converted-continuation)))
                                                                      ,@(macroexp-unprogn converted-condition-form))))
                           (setq converted-condition-form (iter2--merge-continuation-form converted-condition)))
                         (when plain-conditions
                           (setq converted-condition-form `(,operator ,@(nreverse plain-conditions) ,converted-condition-form)))
                         (iter2--add-converted-form converted converted-condition-form)
                         (setq can-yield  t
                               conditions nil))
                     (push converted-condition-form plain-conditions))))
               (unless can-yield
                 (push `(,operator ,@(nreverse plain-conditions)) converted))))

            ;; Handle (if CONDITION THEN [ELSE...]).
            (`(if ,condition ,then . ,else)
             (let ((converted-condition (iter2--convert-form condition))
                   (converted-then      (iter2--convert-form  then))
                   (converted-else      (iter2--convert-progn else)))
               (if (cdr converted-condition)
                   (progn (iter2--add-converted-form converted (car converted-condition))
                          (iter2--finish-chunk converted-chunks converted
                                               `(if ,(cdr converted-condition)
                                                    ,(iter2--merge-continuation-form converted-then)
                                                  ,@(when else (macroexp-unprogn (iter2--merge-continuation-form converted-else))))))
                 (push `(if ,(car converted-condition)
                            ,(iter2--merge-continuation-form converted-then)
                          ,@(when else (macroexp-unprogn (iter2--merge-continuation-form converted-else))))
                       converted))
               (setq can-yield (or (cdr converted-then) (cdr converted-else)))))

            ;; Handle (cond [CLAUSES...]).
            (`(cond . ,clauses)
             (let (converted-clauses
                   conditions-can-yield)
               (while clauses
                 (let* ((clause                   (pop clauses))
                        (converted-condition      (iter2--convert-form (car clause)))
                        (converted-condition-form (car converted-condition))
                        (clause-body              (cdr clause)))
                   (if (cdr converted-condition)
                       (let ((converted-continuation (iter2--convert-form `(cond (,(cdr converted-condition) ,@clause-body) ,@clauses))))
                         (setq converted-condition-form `(progn ,(iter2--continuation-adding-form (list (iter2--merge-continuation-form converted-continuation)))
                                                                ,@(macroexp-unprogn converted-condition-form)))
                         (when converted-clauses
                           (setq converted-condition-form `(cond ,@(nreverse converted-clauses) (t ,@(macroexp-unprogn converted-condition-form)))))
                         (iter2--add-converted-form converted converted-condition-form)
                         (setq conditions-can-yield t
                               clauses              nil))
                     (let ((converted-body (when clause-body (iter2--convert-progn clause-body))))
                       (push `(,(car converted-condition) ,@(when clause-body (macroexp-unprogn (iter2--merge-continuation-form converted-body))))
                             converted-clauses)
                       (when (cdr converted-body)
                         (setq can-yield t))))))
               (if conditions-can-yield
                   (setq can-yield t)
                 (push `(cond ,@(nreverse converted-clauses)) converted))))

            ;; Handle (while CONDITION [WHILE-BODY...]).
            (`(while ,condition . ,while-body)
             (let* ((converted-condition  (iter2--convert-form condition))
                    (converted-while-body (when while-body (iter2--convert-progn while-body))))
               (if (or (cdr converted-condition) (cdr converted-while-body))
                   (let ((special-empty-body (and (null while-body) (eq (cdr converted-condition) iter2--value))))
                     (when while-body
                       (setq converted-while-body (iter2--merge-continuation-form converted-while-body)))
                     (if (cdr converted-condition)
                         ;; Condition yields; whether body yields too is not relevant.
                         (let ((inner-form `(if ,(cdr converted-condition)
                                                (progn (setq ,iter2--continuations (cons (car ,iter2--stack) ,iter2--continuations))
                                                       ,@(macroexp-unprogn (if special-empty-body (car converted-condition) converted-while-body)))
                                              (setq ,iter2--stack (cdr ,iter2--stack)))))
                           (push (iter2--continuation-adding-form (list (if special-empty-body
                                                                            inner-form
                                                                          `(progn ,(iter2--continuation-adding-form (list inner-form))
                                                                                  ,@(macroexp-unprogn (car converted-condition)))))
                                                                  iter2--stack)
                                 converted))
                       ;; Only body yields.
                       (push (iter2--continuation-adding-form (list `(if ,(car converted-condition)
                                                                         (progn (setq ,iter2--continuations (cons (car ,iter2--stack) ,iter2--continuations))
                                                                                ,@(macroexp-unprogn converted-while-body))
                                                                       (setq ,iter2--stack (cdr ,iter2--stack))))
                                                              iter2--stack)
                             converted))
                     (push (iter2--continuation-invocation-form special-empty-body `(car ,iter2--stack)) converted)
                     (setq can-yield t))
                 ;; Nothing yields, the simplest case.
                 (push `(while ,(car converted-condition) ,@(when while-body (macroexp-unprogn (car converted-while-body)))) converted))))

            ;; Handle (let (BINDINGS) LET-BODY) and (let* (BINDINGS) LET-BODY).
            (`(,(and (or 'let 'let*) let-kind) ,bindings . ,let-body)
             (let ((plain-let        (eq let-kind 'let))
                   converted-bindings
                   catcher-outer-bindings
                   catcher-inner-bindings
                   ;; The rest are unused for `let*'.
                   next-continuation-bindings
                   values-to-save-on-stack
                   (num-stack-values 0))
               (while bindings
                 (let* ((binding (pop bindings))
                        var
                        value)
                   (pcase binding
                     ((pred symbolp)
                      (setq var   binding))
                     (`(,(and (pred symbolp) variable))
                      (setq var   variable))
                     (`(,(and (pred symbolp) variable) ,value-form)
                      (setq var   variable
                            value value-form))
                     (_
                      (error "Erroneous binding %S" binding)))
                   (let ((special (special-variable-p var))
                         (literal (iter2--literalp value)))
                     (cond (literal
                            (push binding converted-bindings)
                            (when plain-let
                              (push binding next-continuation-bindings)))
                           ((eq value iter2--stack-state)
                            ;; This is our private internal flag that means "take a
                            ;; previously computed value from the stack".  Stack is only
                            ;; used for plain `let', never for `let*'.
                            (push `(,var (pop ,iter2--stack)) converted-bindings)
                            (push `(,var ,iter2--stack-state) next-continuation-bindings)
                            (setq num-stack-values (1+ num-stack-values)))
                           (t
                            (let* ((converted-value      (iter2--convert-form value))
                                   (converted-value-form (car converted-value)))
                              (if (cdr converted-value)
                                  (progn (if (or plain-let (null converted-bindings))
                                             ;; Yielding before anything is bound.
                                             (progn (when values-to-save-on-stack
                                                      (push (iter2--stack-adding-form (nreverse values-to-save-on-stack)) converted))
                                                    (iter2--add-converted-form converted converted-value-form)
                                                    (iter2--finish-chunk converted-chunks converted
                                                                         (iter2--merge-continuation-form (iter2--convert-form `(,let-kind (,@(nreverse next-continuation-bindings)
                                                                                                                                                  (,var ,(cdr converted-value))
                                                                                                                                                  ,@bindings)
                                                                                                                                         ,@let-body)))))
                                           ;; We need to bind already converted values now.
                                           (push (iter2--let*-yielding-form catcher-outer-bindings catcher-inner-bindings
                                                                            (iter2--merge-continuation-form (iter2--convert-form `(let* ((,var ,iter2--value) ,@bindings) ,@let-body)))
                                                                            (iter2--merge-continuation-form converted-value))
                                                 converted))
                                         (setq bindings  nil
                                               can-yield t))
                                (push `(,var ,converted-value-form) converted-bindings)
                                (when plain-let
                                  (push `(,var ,iter2--stack-state) next-continuation-bindings)
                                  (push converted-value-form values-to-save-on-stack))))))
                     (if (or literal (not special))
                         (push (car converted-bindings) (if special catcher-inner-bindings catcher-outer-bindings))
                       (let ((private-storage-var (make-symbol (format "$%s" (symbol-name var)))))
                         (push `(,private-storage-var ,(nth 1 (car converted-bindings))) catcher-outer-bindings)
                         (push `(,var                 ,private-storage-var)              catcher-inner-bindings)))
                     ;; This is a marker we use to separate bindings for different
                     ;; catchers for `let*'.
                     (when (and special (not plain-let))
                       (push nil catcher-outer-bindings)))))
               (unless can-yield
                 (when (> num-stack-values 1)
                   (push (iter2--stack-head-reversing-form num-stack-values) converted))
                 (let* ((converted-let-body      (iter2--convert-progn let-body))
                        (converted-let-body-form (iter2--merge-continuation-form converted-let-body)))
                   (if (or (null (cdr converted-let-body)) (null catcher-inner-bindings))
                       (progn (push `(,let-kind (,@(nreverse converted-bindings)) ,@(macroexp-unprogn converted-let-body-form)) converted)
                              (setq can-yield (cdr converted-let-body)))
                     ;; Let body yields and we have special (dynamic) bindings.
                     (push (if plain-let
                               `(let (,@(nreverse catcher-outer-bindings))
                                  ,(iter2--catcher-continuation-adding-form `(let (,@(nreverse catcher-inner-bindings))
                                                                               (prog1 ,(iter2--continuation-invocation-form iter2--value)
                                                                                 (unless (eq ,iter2--continuations ,iter2--done)
                                                                                   (push ,iter2--catcher ,iter2--continuations))))
                                                                            converted-let-body-form))
                             (iter2--let*-yielding-form catcher-outer-bindings catcher-inner-bindings converted-let-body-form))
                           converted)
                     (setq can-yield t))))))

            ;; Handle (prog1 VALUE [BODY...]).
            (`(prog1 ,value . ,rest)
             (let ((converted-value (iter2--convert-form  value))
                   (converted-rest  (iter2--convert-progn rest)))
               (if (or (cdr converted-value) (cdr converted-rest))
                   (progn (when (cdr converted-value)
                            (iter2--add-converted-form converted (car converted-value))
                            (iter2--finish-chunk converted-chunks converted))
                          (if (cdr converted-rest)
                              (progn (push `(push ,(or (cdr converted-value) (car converted-value)) ,iter2--stack) converted)
                                     (iter2--add-converted-form converted (car converted-rest))
                                     (iter2--finish-chunk converted-chunks converted `(pop ,iter2--stack)))
                            (push `(prog1 ,(cdr converted-value) ,@rest) converted)))
                 (push `(prog1 ,(car converted-value) ,@(macroexp-unprogn (car converted-rest))) converted))))

            ;; Handle (unwind-protect BODY-FORM CLEANUP-FORMS...).
            (`(unwind-protect ,body-form . ,cleanup-forms)
             (let ((converted-body-form     (iter2--convert-form body-form))
                   (converted-cleanup-forms (iter2--convert-progn cleanup-forms)))
               (when (cdr converted-cleanup-forms)
                 (error "Yielding from cleanup forms in `unwind-protect' is not allowed: %S" cleanup-forms))
               (if (cdr converted-body-form)
                   (progn
                     (push `(setq ,iter2--cleanups (cons (lambda () ,@(macroexp-unprogn (car converted-cleanup-forms))) ,iter2--cleanups)) converted)
                     ;; No need to use private variable names as we don't include any user code.
                     (push (iter2--catcher-continuation-adding-form `(let (result)
                                                                       (unwind-protect
                                                                           (prog1 ,(iter2--continuation-invocation-form iter2--value)
                                                                             (setq result (if (eq ,iter2--continuations ,iter2--done) ,iter2--yielding 'continuing)))
                                                                         (if result
                                                                             (push (if (eq result t)
                                                                                       ;; Completed body, but yielded.  Clean up when control is regained.
                                                                                       (lambda (,iter2--value) ,(iter2--cleanup-invocation-body) ,iter2--value)
                                                                                     ;; Continuing.  Re-add self.
                                                                                     ,iter2--catcher)
                                                                                   ,iter2--continuations)
                                                                           ;; Either exited non-locally, or completed body and haven't yielded.
                                                                           ,(iter2--cleanup-invocation-body))))
                                                                    (iter2--merge-continuation-form converted-body-form))
                           converted)
                     (setq can-yield            t
                           iter2--cleanups-used t))
                   (push `(unwind-protect ,(car converted-body-form) ,@(macroexp-unprogn (car converted-cleanup-forms))) converted))))

            ;; Handle (catch TAG BODY).
            (`(catch ,tag . ,catch-body)
             (let* ((converted-tag      (iter2--convert-form tag))
                    (converted-tag-form (car converted-tag)))
               (when (cdr converted-tag)
                 (iter2--add-converted-form converted converted-tag-form)
                 (iter2--finish-chunk converted-chunks converted)
                 (setq converted-tag-form (cdr converted-tag)))
               (let ((converted-catch-body (iter2--convert-progn catch-body)))
                 (if (cdr converted-catch-body)
                     (let ((literal-tag (iter2--literalp converted-tag-form)))
                       ;; No need to use private variable names as we don't include any user code.
                       (push (iter2--catcher-continuation-adding-form `(let (completed-normally)
                                                                         (prog1 (catch ,(if literal-tag converted-tag-form 'tag)
                                                                                  (prog1 ,(iter2--continuation-invocation-form iter2--value)
                                                                                    (setq completed-normally t)
                                                                                    (unless (eq ,iter2--continuations ,iter2--done)
                                                                                      (push ,iter2--catcher ,iter2--continuations))))
                                                                           (unless completed-normally
                                                                             (setq ,iter2--continuations ,iter2--done
                                                                                   ,iter2--stack         ,iter2--stack-state))))
                                                                      (iter2--merge-continuation-form converted-catch-body)
                                                                      `(,iter2--stack-state ,iter2--stack)
                                                                      (unless literal-tag `(tag ,converted-tag-form)))
                             converted)
                       (setq can-yield t))
                   (push `(catch ,converted-tag-form ,@(macroexp-unprogn (car converted-catch-body))) converted)))))

            ;; Handle (condition-case VAR BODY-FORM HANDLERS...).
            (`(condition-case ,var ,body-form . ,handlers)
             (let ((converted-body (iter2--convert-form body-form))
                   converted-handlers)
               (dolist (handler handlers)
                 (pcase handler
                   (`(,condition . ,handler-body)
                    (let ((converted-handler (iter2--convert-progn handler-body)))
                      (push `(,condition ,@(macroexp-unprogn (iter2--merge-continuation-form converted-handler))) converted-handlers)
                      (when (cdr converted-handler)
                        (setq can-yield t))))
                   (_
                    (error "Invalid `condition-case' error handler: %S" handler))))
               (setq converted-handlers (nreverse converted-handlers))
               (if (cdr converted-body)
                   (progn (push (iter2--catcher-continuation-adding-form `(condition-case ,var
                                                                              (prog1 ,(iter2--continuation-invocation-form iter2--value)
                                                                                (unless (eq ,iter2--continuations ,iter2--done)
                                                                                  (push ,iter2--catcher ,iter2--continuations)))
                                                                            ,@(mapcar (lambda (handler)
                                                                                        `(,(car handler)
                                                                                          (setq ,iter2--continuations ,iter2--done ,iter2--stack ,iter2--stack-state)
                                                                                          ,@(cdr handler)))
                                                                                      converted-handlers))
                                                                         (iter2--merge-continuation-form converted-body)
                                                                         `(,iter2--stack-state ,iter2--stack))
                                converted)
                          (setq can-yield t))
                 (push `(condition-case ,var ,(car converted-body) ,@converted-handlers) converted))))

            ;; Handle (iter-yield VALUE).
            (`(iter-yield . ,rest)
             (unless (and (consp rest) (null (cdr rest)))
               (error "Form `iter-yield' must be used with exactly one argument: %S" form))
             (let* ((converted-value      (iter2--convert-form (car rest)))
                    (converted-value-form (car converted-value)))
               (when iter2-generate-tracing-functions
                 (setq converted-value-form `(let ((,iter2--value ,converted-value-form))
                                               (iter2--do-trace "yielding %S" ,iter2--value)
                                               ,iter2--value)))
               (when (cdr converted-value)
                 (iter2--add-converted-form converted converted-value-form)
                 (iter2--finish-chunk converted-chunks converted)
                 (setq converted-value-form (cdr converted-value)))
               (if (iter2--literal-or-variable-p converted-value-form)
                   (progn (push `(setq ,iter2--yielding t) converted)
                          (push converted-value-form converted))
                 ;; It might be unsafe to set yielding flag first: what if the value
                 ;; form exits non-locally?
                 (push `(prog1 ,converted-value-form (setq ,iter2--yielding t)) converted))
               (setq can-yield t)))

            ;; Handle `save-excursion'.
            (`(save-excursion . ,body)
             (let ((converted-body (iter2--convert-progn body)))
               (if (cdr converted-body)
                   (progn (push (iter2--catcher-continuation-adding-form `(save-excursion
                                                                            ;; Byte compiler gives a dumb warning here,
                                                                            ;; suggesting to use `with-current-buffer'.
                                                                            (with-no-warnings (set-buffer buffer))
                                                                            (goto-char  point)
                                                                            (prog1 ,(iter2--continuation-invocation-form iter2--value)
                                                                              (unless (eq ,iter2--continuations ,iter2--done)
                                                                                (setq buffer (current-buffer)
                                                                                      point  (point))
                                                                                (push ,iter2--catcher ,iter2--continuations))))
                                                                         (iter2--merge-continuation-form converted-body)
                                                                         '(buffer (current-buffer))
                                                                         '(point  (point)))
                                converted)
                          (setq can-yield t))
                 (push `(save-excursion ,@(macroexp-unprogn (car converted-body))) converted))))

            ;; Handle `save-current-buffer'.
            (`(save-current-buffer . ,body)
             (let ((converted-body (iter2--convert-progn body)))
               (if (cdr converted-body)
                   (progn (push (iter2--catcher-continuation-adding-form `(save-current-buffer
                                                                            (set-buffer buffer)
                                                                            (prog1 ,(iter2--continuation-invocation-form iter2--value)
                                                                              (unless (eq ,iter2--continuations ,iter2--done)
                                                                                (setq buffer (current-buffer))
                                                                                (push ,iter2--catcher ,iter2--continuations))))
                                                                         (iter2--merge-continuation-form converted-body)
                                                                         '(buffer (current-buffer)))
                                converted)
                          (setq can-yield t))
                 (push `(save-current-buffer ,@(macroexp-unprogn (car converted-body))) converted))))

            ;; Handle `save-restriction'.
            (`(save-restriction . ,body)
             (let ((converted-body (iter2--convert-progn body)))
               (if (cdr converted-body)
                   (progn (push (iter2--catcher-continuation-adding-form `(save-restriction
                                                                            (narrow-to-region point-min point-max)
                                                                            (prog1 ,(iter2--continuation-invocation-form iter2--value)
                                                                              (unless (eq ,iter2--continuations ,iter2--done)
                                                                                (setq point-min (point-min)
                                                                                      point-max (point-max))
                                                                                (push ,iter2--catcher ,iter2--continuations))))
                                                                         (iter2--merge-continuation-form converted-body)
                                                                         '(point-min (point-min))
                                                                         '(point-max (point-max)))
                                converted)
                          (setq can-yield t))
                 (push `(save-restriction ,@(macroexp-unprogn (car converted-body))) converted))))

            ;; Handle `save-match-data' macro: not a special form, but without special
            ;; handling doesn't produce intended results in generator functions.
            (`(save-match-data . ,body)
             (let ((converted-body (iter2--convert-progn body)))
               (if (cdr converted-body)
                   (progn (push (iter2--catcher-continuation-adding-form `(save-match-data
                                                                            (set-match-data match-data)
                                                                            (prog1 ,(iter2--continuation-invocation-form iter2--value)
                                                                              (unless (eq ,iter2--continuations ,iter2--done)
                                                                                (match-data nil match-data)
                                                                                (push ,iter2--catcher ,iter2--continuations))))
                                                                         (iter2--merge-continuation-form converted-body)
                                                                         '(match-data (match-data)))
                                converted)
                          (setq can-yield t))
                 (push `(save-match-data ,@(macroexp-unprogn (car converted-body))) converted))))

            ;; Handle `with-no-warnings': while not a special form, it requires special handling.
            (`(with-no-warnings . ,body)
             (let ((converted-body (iter2--convert-progn body)))
               (push `(with-no-warnings ,@(macroexp-unprogn (iter2--merge-continuation-form converted-body))) converted)
               (setq can-yield (cdr converted-body))))

            ;; Handle all other non-atomic forms.
            (`(,name . ,arguments)
             ;; Several special forms are handled more-or-less like function calls.
             (when (and (special-form-p name) (not (memq name '(setq setq-default throw))))
               (error "Special form %S incorrect or not supported" form))
             (let (converted-arguments
                   next-continuation-arguments
                   arguments-to-save-on-stack
                   (num-stack-arguments 0))
               (while arguments
                 (let ((argument (pop arguments)))
                   (cond ((eq argument iter2--stack-state)
                          ;; This is our private internal flag that means "take a
                          ;; previously computed value from the stack".
                          (push `(pop ,iter2--stack) converted-arguments)
                          (push iter2--stack-state   next-continuation-arguments)
                          (setq num-stack-arguments (1+ num-stack-arguments)))
                         ((or (iter2--literalp argument) (and (memq name '(setq setq-default)) (= (% (length converted-arguments) 2) 0)))
                          (push argument converted-arguments)
                          (push argument next-continuation-arguments))
                         (t
                          (let ((converted-argument (iter2--convert-form argument)))
                            (if (cdr converted-argument)
                                (progn (when arguments-to-save-on-stack
                                         (push (iter2--stack-adding-form (nreverse arguments-to-save-on-stack)) converted))
                                       (iter2--add-converted-form converted (car converted-argument))
                                       (push `(,name ,@(nreverse next-continuation-arguments) ,(cdr converted-argument) ,@arguments) body)
                                       (setq arguments nil
                                             can-yield t))
                              (push (car converted-argument) converted-arguments)
                              (push iter2--stack-state       next-continuation-arguments)
                              (push (car converted-argument) arguments-to-save-on-stack)))))))
               (unless can-yield
                 (when (> num-stack-arguments 1)
                   (push (iter2--stack-head-reversing-form num-stack-arguments) converted))
                 (push (cons name (nreverse converted-arguments)) converted))))

            (_
             (push form converted)))
          (when can-yield
            (iter2--finish-chunk converted-chunks converted)
            (setq can-yield nil))))

      (setq converted (nreverse converted))
      (if converted-chunks
          (progn (setq converted-chunks (nreverse converted-chunks))
                 (cons (if (cdr converted-chunks)
                           `(progn ,(iter2--continuation-adding-form (reverse (cdr converted-chunks)))
                                   ,@(macroexp-unprogn (car converted-chunks)))
                         (car converted-chunks))
                       (if converted (macroexp-progn converted) iter2--value)))
        (cons (macroexp-progn converted) nil)))))

(defun iter2--convert-form-tracer (function form)
  (let ((result (funcall function form)))
    (if (or (atom form) (null iter2-tracing-function))
        result
      (let ((indentation            (make-string (* iter2--converter-depth 4) ? ))
            (iter2--converter-depth (1+ iter2--converter-depth)))
        (funcall iter2-tracing-function "%s" (replace-regexp-in-string "^" indentation (format "FORM: %s" (iter2--pp-to-string form 60 6)) t t))
        (funcall iter2-tracing-function "%s" (replace-regexp-in-string "^" indentation (format "--->: %s\n+:    %s"
                                                                                               (iter2--pp-to-string (car result) 60 6)
                                                                                               (iter2--pp-to-string (cdr result) 60 6))
                                                                       t t))
        result))))

(defun iter2--pp-to-string (object &optional max-single-line-length indent-by)
  (let* ((print-quoted t)
         (string       (prin1-to-string object)))
    (when (and max-single-line-length (> (length string) max-single-line-length))
      (setq string (string-trim-right (pp-to-string object))))
    (when (and indent-by (> indent-by 0))
      (setq string (replace-regexp-in-string "\n" (concat "\n" (make-string indent-by ? )) string t t)))
    string))

(defun iter2--debug-converter (enable)
  (if enable
      (advice-add #'iter2--convert-form :around #'iter2--convert-form-tracer)
    (advice-remove #'iter2--convert-form #'iter2--convert-form-tracer)))

(defun iter2--continuation-invocation-form (value &optional lambda)
  (if iter2-generate-tracing-functions
      `(let ((function ,(or lambda `(pop ,iter2--continuations))))
         (iter2--do-trace "invoking %S with value %S" function ,value)
         (let ((iter2--tracing-depth (1+ iter2--tracing-depth)))
           (funcall function ,value)))
    `(funcall ,(or lambda `(pop ,iter2--continuations)) ,value)))

(defun iter2--cleanup-invocation-body ()
  (if iter2-generate-tracing-functions
      `(let ((function (pop ,iter2--cleanups)))
         (iter2--do-trace "cleaning up using %S" function)
         (funcall function))
    `(funcall (pop ,iter2--cleanups))))

(defun iter2--merge-continuation-form (converted &optional var)
  (let ((converted-form    (car converted))
        (continuation-form (cdr converted)))
    (if (and continuation-form (not (eq continuation-form iter2--value)))
        `(progn ,(iter2--continuation-adding-form (list continuation-form) var) ,@(macroexp-unprogn converted-form))
      converted-form)))

(defun iter2--continuation-adding-form (new-continuations &optional var)
  (let ((value (or var iter2--continuations)))
    (while new-continuations
      (setq value `(cons (lambda (,iter2--value) ,@(macroexp-unprogn (pop new-continuations))) ,value)))
    `(setq ,(or var iter2--continuations) ,value)))

(defun iter2--catcher-continuation-adding-form (catcher-body next-continuation &rest additional-catcher-outer-bindings)
  `(setq ,iter2--continuations
         (cons (let ((,iter2--done ,iter2--continuations)
                     ,@(delq nil additional-catcher-outer-bindings)
                     ,iter2--catcher)
                 (setq ,iter2--catcher (lambda (,iter2--value) ,@(macroexp-unprogn catcher-body))))
               (cons (lambda (,iter2--value) ,@(macroexp-unprogn next-continuation))
                     ,iter2--continuations))))

(defun iter2--let*-yielding-form (catcher-outer-bindings catcher-inner-bindings continuation &optional form-before-continuation)
  (let (main-bindings)
    (while (and catcher-outer-bindings (car catcher-outer-bindings))
      (push (pop catcher-outer-bindings) main-bindings))
    (setq catcher-outer-bindings (cdr catcher-outer-bindings))
    (let ((form `(,(iter2--continuation-adding-form (list continuation))
                  ,@(when form-before-continuation (macroexp-unprogn form-before-continuation)))))
      (setq form (if main-bindings `(let* (,@main-bindings) ,@form) `(progn ,@form)))
      (while catcher-inner-bindings
        (let (outer-bindings)
          (while (and catcher-outer-bindings (car catcher-outer-bindings))
            (push (pop catcher-outer-bindings) outer-bindings))
          (setq catcher-outer-bindings (cdr catcher-outer-bindings))
          (setq form (iter2--catcher-continuation-adding-form `(let (,(pop catcher-inner-bindings))
                                                                 (prog1 ,(iter2--continuation-invocation-form iter2--value)
                                                                   (unless (eq ,iter2--continuations ,iter2--done)
                                                                     (push ,iter2--catcher ,iter2--continuations))))
                                                              form))
          (when outer-bindings
            (setq form `(let* (,@outer-bindings)
                          ,form)))))
      form)))

(defun iter2--stack-adding-form (new-elements)
  (let ((value iter2--stack))
    (while new-elements
      (setq value `(cons ,(pop new-elements) ,value)))
    `(setq ,iter2--stack ,value)))

(defun iter2--stack-head-reversing-form (n)
  (pcase n
    (2 `(iter2--reverse-stack-head-2 ,iter2--stack))
    (3 `(iter2--reverse-stack-head-3 ,iter2--stack))
    (_ `(setq ,iter2--stack (iter2--reverse-stack-head-n ,iter2--stack ,(1- n))))))


;; Internal helpers for generated functions.

(defun iter2--do-clean-up (cleanups)
  (if (cdr cleanups)
      (unwind-protect
          (funcall (car cleanups))
        (iter2--do-clean-up (cdr cleanups)))
    (funcall (car cleanups))))

(defun iter2--reverse-stack-head-2 (stack)
  (let ((x      (car stack))
        (link-2 (cdr stack)))
    (setcar stack  (car link-2))
    (setcar link-2 x)))

(defun iter2--reverse-stack-head-3 (stack)
  (let ((x      (car  stack))
        (link-3 (cddr stack)))
    (setcar stack  (car link-3))
    (setcar link-3 x)))

(defun iter2--reverse-stack-head-n (stack n-1)
  (let* ((last-head-cons (nthcdr n-1 stack))
         (stack-tail     (cdr last-head-cons)))
    (setcdr last-head-cons nil)
    (nconc (nreverse stack) stack-tail)))

(defun iter2--do-trace (format-string &rest arguments)
  (when iter2-tracing-function
    (let ((print-level  (if (eq iter2-tracing-print-level  t) print-level  iter2-tracing-print-level))
          (print-length (if (eq iter2-tracing-print-length t) print-length iter2-tracing-print-length)))
      (apply iter2-tracing-function (concat "%siter2: " format-string) (cons (make-string (* iter2--tracing-depth 4) ? ) arguments)))))


;; Make sure that we are still compatible with `generator'.  I couldn't make it work like
;; I wanted with fewer `eval's.
(eval-after-load 'iter2
  (eval `(unless (let* ((it (funcall (iter2-lambda () (iter-yield 1)))))
                   (and (equal (iter-next it) 1) (condition-case error (progn (iter-next it 2) nil) (iter-end-of-sequence (equal (cdr error) 2)))))
           (warn "Compatibility of `iter2' with `generator' package appears broken; please report this to maintainer (Emacs version: %s)" (emacs-version)))
        t))


(defun iter2-log-message (format-string &rest arguments)
  "Like built-in `message', but only write to `*Messages*' buffer."
  (let ((inhibit-message (or inhibit-message (not noninteractive))))
    (apply #'message format-string arguments)))


;; Work around missing Edebug specification for `iter-do' macro.
(when (and (fboundp 'iter-do) (null (get 'iter-do 'edebug-form-spec)))
  (put 'iter-do 'edebug-form-spec '((symbolp form) body)))


(provide 'iter2)

;;; iter2.el ends here
