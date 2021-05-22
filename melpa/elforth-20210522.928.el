;;; elforth.el --- Do you have what it takes to hack Emacs Lisp in Forth? -*- lexical-binding: t -*-

;; Copyright 2021 Lassi Kortela
;; SPDX-License-Identifier: ISC

;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/elforth
;; Package-Version: 20210522.928
;; Package-Commit: 2d8540434a28e7edaa04a992c3c362832b2fd61e
;; Package-Requires: ((emacs "26.1"))
;; Version: 0.1.0
;; Keywords: games

;; This file is not part of GNU Emacs.

;;; Commentary:

;; It's well established that Real Programmers use Emacs, and equally
;; well known that the determined Real Programmer can write Forth in
;; any language.  This package is the logical conclusion.  Those who
;; know what is right and true are now liberated to program the One
;; True Editor in the One True Language.

;; Try writing some El Forth in the *scratch* buffer, highlighting it,
;; and doing M-x elforth-eval-region. For example:

;; "hello" " " "world" 3 nlist 'concat apply

;; Or if you're feeling festive:

;; "Party like it's " 1970 number-to-string concat "!" concat

;;; Code:

(require 'cl-lib)

(defvar elforth-read-expression-history '()
  "History of El Forth expressions read from the minibuffer.")

(defvar elforth--stack '()
  "Holds the El Forth data stack. First value is top of stack.")

(defvar elforth--dictionary '()
  "Holds the definitions of El Forth words.

A word is a 3-element list:
- a lambda taking iargs and returning a list of oargs.
- list of iarg names as symbols
- list of oarg names as symbols")

(defvar elforth--variables '()
  "Values of the one-letter variables a..z for El Forth.")

(defun elforth--show-list (interactive-p list repr)
  "Internal fuction to help show LIST using REPR when INTERACTIVE-P."
  (prog1 list
    (when interactive-p
      (message "%s"
               (if (null list) "Empty"
                 (with-temp-buffer
                   (let ((item (car list)))
                     (insert (funcall repr item)))
                   (dolist (item (cdr list))
                     (insert " " (funcall repr item)))
                   (buffer-string)))))))

(defun elforth-show-variables (interactive-p)
  "Show the contents of the El Forth variables a..z in the echo area.

INTERACTIVE-P is non-nil when called interactively."
  (interactive (list t))
  (elforth--show-list interactive-p elforth--variables
                      (lambda (pair)
                        (let ((variable (car pair)) (value (cdr pair)))
                          (format "%S=%S" variable value)))))

(defun elforth-show-stack (interactive-p)
  "Show the contents of the El Forth stack in the echo area.

INTERACTIVE-P is non-nil when called interactively."
  (interactive (list t))
  (elforth--show-list interactive-p (reverse elforth--stack)
                      (lambda (obj) (format "%S" obj))))

(defun elforth-clear-stack ()
  "Clear the El Forth stack."
  (interactive)
  (setq elforth--stack '())
  (elforth-show-stack (called-interactively-p 'interactive)))

(defun elforth-push (value)
  "Push VALUE to the El Forth stack."
  (setq elforth--stack (cons value elforth--stack)))

(defun elforth-push-many (values)
  "Push zero or more VALUES (in left to right order) to the El Forth stack."
  (setq elforth--stack (append (reverse values) elforth--stack)))

(defun elforth-pop-many (n)
  "Pop N values from the El Forth stack or signal an error."
  (let ((n (max 0 n)))
    (cond ((> n (length elforth--stack))
           (error "The stack does not have %d values" n))
          (t
           (let ((values (reverse (cl-subseq elforth--stack 0 n))))
             (setq elforth--stack (cl-subseq elforth--stack n))
             values)))))

(defun elforth--alist-upsert (alist name value)
  "Internal function to update or insert NAME and VALUE in ALIST."
  (sort (cons (cons name value)
              (cl-remove-if (lambda (entry) (equal name (car entry)))
                            alist))
        (lambda (a b) (string< (car a) (car b)))))

(defun elforth-only-variable-p (variable)
  "Return t if VARIABLE is one of the Forth-only variables a..z."
  (and (symbolp variable)
       (let ((name (symbol-name variable)))
         (and (= 1 (length name))
              (<= ?a (elt name 0) ?z)))))

(defun elforth-fetch (variable)
  "Return the value of VARIABLE.

If VARIABLE is one of the one-letter Forth-only variables a..z,
use it.  Otherwise use the Emacs Lisp variable with the name."
  (cond ((not (symbolp variable))
         (error "Trying to fetch non-symbol: %S" variable))
        ((elforth-only-variable-p variable)
         (cdr (or (assq variable elforth--variables)
                  (error "No such variable: %S" variable))))
        ((not (boundp variable))
         (error "No such variable: %S" variable))
        (t
         (symbol-value variable))))

(defun elforth-store (variable value)
  "Set VARIABLE to VALUE.

If VARIABLE is one of the one-letter Forth-only variables a..z,
set it.  Otherwise set the global binding of the Emacs Lisp
variable with the name.  Note that Emacs Lisp keeps variables and
functions in separate namespaces, so you can set a variable with
the same name as a function without breaking the function."
  (if (elforth-only-variable-p variable)
      (setq elforth--variables
            (elforth--alist-upsert elforth--variables variable value))
    (setf (symbol-value variable) value))
  value)

;; Lisp functions can have optional arguments. Additionally, they can
;; have a rest argument that rolls any number of remaining args into
;; one list.

;; A Forth word should ideally always consume the same number of items
;; from the stack. The question arises of how to fit variable-arity
;; Lisp words into this Forth mindset.

;; Our solution is twofold:

;; - The `apply' word family takes a set number of items from the
;;   stack (or one item, which is a list) and calls a Lisp function
;;   with them.

;; - Calling a word directly without using `apply' will determine a
;;   default arity for that word, and will take that many items from
;;   the stack and use them as the arguments.

;; The default arity is the number of required arguments taken by the
;; Lisp function. In other words, without optional and rest args.

;; However, some functions have only a rest argument and no required
;; arguments. Good examples are `+' and `concat'. These are almost
;; useless to call with no arguments, so we use a default arity of 2.
;; That matches our intuition about infix operators from math class,
;; and also the arity of the corresponding ANS Forth words.

;; Some Lisp functions are more intuitive or useful when optional args
;; are supplied, than when they are not. A good example is
;; `substring': (substring "hello" 1 3) is more intuitive and useful
;; than (substring "hello"). We let (put 'substring 'elforth-arity 3)
;; specify a default arity for such functions on a case-by-case basis.

;; Remember that when the default arity does not serve your need, it's
;; always possible to circumvent it and pass the exact number of args
;; you prefer by using the `apply' family.

(defun elforth--ordinary-function-p (func)
  "Internal function to determine whether FUNC is ordinary."
  (let ((max-args (cdr (func-arity func))))
    (or (eq 'many max-args)
        (and (integerp max-args) (>= max-args 0)))))

(defun elforth--resolve-function (func)
  "Internal function to validate FUNC and resolve into a normal form."
  (or (and (symbolp func)
           (cdr (assq func elforth--dictionary)))
      (and (functionp func)
           (if (elforth--ordinary-function-p func)
               func
             (error "Trying to apply special form: %S" func)))
      (error "No such function: %S" func)))

(defun elforth--rfunc-min-arity (zero-case func)
  "Internal function to get a minimum arity for resolved FUNC.

ZERO-CASE is the arity to return for functions that take no
required arguments and arbitrarily many optional arguments."
  (if (functionp func)
      (let* ((arity (func-arity func))
             (min-args (car arity))
             (max-args (cdr arity)))
        (if (and (= 0 min-args) (eq 'many max-args)) zero-case min-args))
    (let ((iargs (elt func 1)))
      (length iargs))))

(defun elforth--rfunc-default-arity (func)
  "Internal function to get default arity for resolved FUNC."
  (or (and (functionp func) (get func 'elforth-arity))
      (elforth--rfunc-min-arity 2 func)))

(defun elforth--rfunc-too-few-args-p (func n)
  "Internal function to check whether resolved FUNC can take N args."
  (< n (elforth--rfunc-min-arity 0 func)))

(defun elforth--rfunc-too-many-args-p (func n)
  "Internal function to check whether resolved FUNC can take N args."
  (and (functionp func)
       (let ((max-args (cdr (func-arity func))))
         (and (integerp max-args) (> n max-args)))))

(defun elforth--rfunc-apply (func args)
  "Internal function to apply resolved FUNC to ARGS."
  (if (functionp func)
      (list (apply func args))
    (let ((lam (elt func 0)))
      (apply lam args))))

(defun elforth-apply (func args)
  "Call the El Forth or Emacs Lisp function FUNC with ARGS."
  (let ((func (elforth--resolve-function func))
        (n (length args)))
    (cond ((elforth--rfunc-too-few-args-p func n)
           (error "Too few arguments"))
          ((elforth--rfunc-too-many-args-p func n)
           (error "Too many arguments"))
          (t
           (elforth-push-many (elforth--rfunc-apply func args))))))

(defun elforth-execute (func)
  "Call the El Forth or Emacs Lisp function FUNC with args from stack."
  (let* ((func (elforth--resolve-function func))
         (args (elforth-pop-many (elforth--rfunc-default-arity func))))
    (elforth-push-many (elforth--rfunc-apply func args))))

(defun elforth--define (name definition)
  "Internal function to set NAME to DEFINITION in the dictionary."
  (cl-assert (symbolp name))
  (setq elforth--dictionary
        (elforth--alist-upsert elforth--dictionary name definition))
  name)

(defmacro define-elforth-word (name stack-effect &rest body)
  "Define the El Forth word NAME according to STACK-EFFECT and BODY."
  (let ((iargs '())
        (oargs '()))
    (let ((tail stack-effect) (had-dashes-p nil))
      (while tail
        (let ((arg (car tail)))
          (cond ((and had-dashes-p (eq '-- arg))
                 (error "Bad stack effect: %S" stack-effect))
                ((eq '-- arg)
                 (setq had-dashes-p t))
                ((symbolp arg)
                 (if (not had-dashes-p)
                     (setq iargs (nconc iargs (list arg)))
                   (setq oargs (nconc oargs (list arg)))))
                (t (error "Bad argument: %S" arg))))
        (setq tail (cdr tail))))
    (let* ((io-args
            (cl-remove-if (lambda (arg) (not (member arg oargs)))
                          iargs))
           (o-only-args
            (cl-remove-if (lambda (arg) (member arg io-args))
                          oargs)))
      `(elforth--define
        ',name
        (list (lambda ,iargs
                (let ,o-only-args
                  (progn ,@body)
                  (list ,@oargs)))
              ',iargs
              ',oargs)))))

(define-elforth-word apply (list func --)
  (elforth-apply func list))

(define-elforth-word 1apply (func --)
  (elforth-apply func (elforth-pop-many 1)))

(define-elforth-word 2apply (func --)
  (elforth-apply func (elforth-pop-many 2)))

(define-elforth-word 3apply (func --)
  (elforth-apply func (elforth-pop-many 3)))

(define-elforth-word napply (func n --)
  (elforth-apply func (elforth-pop-many n)))

(define-elforth-word 1call (func --)
  (elforth-apply func (elforth-pop-many 1)))

(define-elforth-word 2call (func --)
  (elforth-apply func (elforth-pop-many 2)))

(define-elforth-word @ (variable -- value)
  (setq value (elforth-fetch variable)))

(define-elforth-word ! (value variable --)
  (elforth-store variable value))

(define-elforth-word dup (a -- a a))
(define-elforth-word drop (_ --))
(define-elforth-word swap (a b -- b a))
(define-elforth-word rot (x a b -- a b x))
(define-elforth-word clear (--) (elforth-clear-stack))
(define-elforth-word depth (-- n) (setq n (length elforth--stack)))
(define-elforth-word 2list (-- list) (setq list (elforth-pop-many 2)))
(define-elforth-word 3list (-- list) (setq list (elforth-pop-many 3)))
(define-elforth-word nlist (n -- list) (setq list (elforth-pop-many n)))
(define-elforth-word unlist (list --) (elforth-push-many list))

(define-elforth-word min (a b -- x) (setq x (min a b)))
(define-elforth-word max (a b -- x) (setq x (max a b)))

(define-elforth-word negate (a -- a) (setq a (- a)))

(put 'subseq 'elforth-arity 3)
(put 'substring 'elforth-arity 3)

(defun elforth-read-from-string (string)
  "Read list of El Forth words from STRING."
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (let ((words '()))
      (condition-case _ (while t (push (read (current-buffer)) words))
        (end-of-file (nreverse words))))))

(defun elforth-read-expression (prompt)
  "Read list of El Forth words from the minibuffer using PROMPT."
  (elforth-read-from-string
   (read-string prompt nil 'elforth-read-expression-history "")))

;;;###autoload
(defun elforth-eval-expression (list)
  "Evaluate LIST as El Forth words."
  (interactive (list (elforth-read-expression "El Forth eval: ")))
  (dolist (word list)
    (cond ((and (consp word)
                (= 2 (length word))
                (eq 'quote (elt word 0)))
           (let ((word (elt word 1)))
             (unless (symbolp word)
               (error "Execution token is not a symbol: %S" word))
             (elforth-push word)))
          ((and (symbolp word) (not (elforth-only-variable-p word)))
           (elforth-execute word))
          (t
           (elforth-push word))))
  (elforth-show-stack (called-interactively-p 'interactive)))

(defun elforth-eval-string (string)
  "Read STRING as El Forth code and evaluate it."
  (elforth-eval-expression (elforth-read-from-string string))
  (elforth-show-stack (called-interactively-p 'interactive)))

;;;###autoload
(defun elforth-eval-region (start end)
  "Read text between START and END as El Forth code and evaluate it."
  (interactive "r")
  (elforth-eval-string (buffer-substring-no-properties start end))
  (elforth-show-stack (called-interactively-p 'interactive)))

(provide 'elforth)

;;; elforth.el ends here
