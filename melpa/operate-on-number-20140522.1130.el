;;; operate-on-number.el --- Operate on number at point with arithmetic functions

;; Copyright (c) 2014 Akinori MUSHA
;;
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;; SUCH DAMAGE.

;; Author: Akinori MUSHA <knu@iDaemons.org>
;; URL: https://github.com/knu/operate-on-number.el
;; Package-Version: 20140522.1130
;; Package-Commit: 6a17272e2b6e23260edb1b5eeb01905a1f37e0a6
;; Created: 15 May 2014
;; Version: 1.1.0
;; Keywords: editing

;;; Commentary:
;;
;; Suppose the point is on some number.  If you want to double it,
;; invoke `operate-on-number-at-point' followed by some keys: * 2 RET.
;;
;; Alternatively, you can bind `apply-operation-to-number-at-point' to
;; <some prefix> *, and you will be able to just type the sequence to
;; double a number, which function uses the last key typed as function
;; specifier and supplies with a default argument which in this case
;; of * is 2.  This command takes numeric argument, so you can type
;; M-3 <some prefix> * to triple the number.
;;
;; For the predefined operation list and how to define a new
;; operation, see `operate-on-number-at-point-alist'.
;;
;; It is recommended using smartrep to bind the functions like this:
;;
;;   (smartrep-define-key global-map "C-."
;;     '(("+" . apply-operation-to-number-at-point)
;;       ("-" . apply-operation-to-number-at-point)
;;       ("*" . apply-operation-to-number-at-point)
;;       ("/" . apply-operation-to-number-at-point)
;;       ("\\" . apply-operation-to-number-at-point)
;;       ("^" . apply-operation-to-number-at-point)
;;       ("<" . apply-operation-to-number-at-point)
;;       (">" . apply-operation-to-number-at-point)
;;       ("#" . apply-operation-to-number-at-point)
;;       ("%" . apply-operation-to-number-at-point)
;;       ("'" . operate-on-number-at-point)))
;;

;;; Code:

(require 'calc-bin)

;;;###autoload
(defun find-number-at-point ()
  "Search the current line till EOL for a number.
If a pure number is found, move point to the beginning of the
number and return the value.  Raise an error otherwise."
  (interactive)
  (let (num)
    (goto-char
     (save-excursion
       (unless (looking-back "[0-9]")
         (skip-chars-forward "^0-9\r\n")
         (or (looking-at "[0-9]")
             (error "No number found before eol"))
         (forward-char))
       (backward-sexp)
       (or (setq num (number-at-point))
           (error "Not a pure number"))
       (point)))
    num))

(defgroup operate-on-number nil
  "Operate on number at point."
  :prefix "apply-on-number-at-point-"
  :group 'editing)

(defcustom operate-on-number-at-point-alist
  '((?+ (1) +)
    (?- (1) -)
    (?* (2) *)
    (?/ (2) /)
    (?\\ (2) %
         :read t)
    (?^ (2) expt)
    (?< (1) ash
        :display "<<")
    (?> (1) (lambda (a b) (ash a (- b)))
        :display ">>")
    (?b () math-format-binary)
    (?o () (lambda (a) (format "%o" a)))
    (?x () (lambda (a) (format "%x" a)))
    (?X () (lambda (a) (format "%X" a)))
    (?# (10) (lambda (a b)
               (let ((calc-number-radix b))
                 (math-format-radix a)))
        :display "in base"
        :read t)
    (?% ("%s") (lambda (a b) (format b a))
        :display "formatted with"
        :read t))
  "A list of (KEY DEFARGS FUNC ...).

KEY is used immediately following `apply-on-number-at-point' to
select an operation.

DEFARGS is a list of default arguments, which length is taken as
the number of additional operands required for the operation.
Currently this length must be zero or one.

FUNC is a function for the operation.

After that comes an optional inline property list in which the
following keys are available:

:display	Specifies the human readable representation for
		the operation.

:read		If this property is non-nil,
		`apply-operation-to-number-at-point' always asks
		user for an additional argument, using a value in
		DEFARGS as default."
  :type '(repeat
          (list (character :tag "Key")
                (repeat :tag "Default Arguments"
                        (sexp :tag "Argument"))
                (function :tag "Function")
                (repeat :inline t :tag "Property List"
                        (list :inline t
                              (symbol :tag "Option")
                              (sexp :tag "Value")))))
  :set (lambda (sym val)
         (set-default sym
                      (mapcar #'(lambda (entry)
                                  (let ((key (nth 0 entry))
                                        (arg1 (nth 1 entry))
                                        (arg2 (nth 2 entry))
                                        (plist (nthcdr 3 entry)))
                                    (if (and (listp arg2)
                                             (>= 1 (length arg2)))
                                        ;; compatibility
                                        (append (list key arg2 arg1) plist)
                                      entry))) val)))
  :group 'operate-on-number)

(defun apply-to-number-at-point (func args &optional plist)
  "Apply FUNC on a number at point with ARGS.
For possible keys of PLIST, see `operate-on-number-at-point-alist'."
  (let* ((result (apply func (find-number-at-point) args))
         (bounds (bounds-of-thing-at-point 'sexp)))
    (delete-region (car bounds) (cdr bounds))
    (insert (format "%s" result))
    (backward-sexp)
    result))

;;;###autoload
(defun apply-operation-to-number-at-point (&optional key read-args)
  "Apply an operation specified by KEY on a number at point.

If called interactively, use the last key input as KEY.

If the operation requires an additional operand, it is taken from
one of the following sources in the order named:

1. Prefix argument if given

2. Value read from keyboard if READ-ARGS is non-nil or the :read
   property is non-nil

3. Default argument predefined in `operate-on-number-at-point-alist'"
  (interactive (list
                (let ((keys (this-command-keys-vector)))
                  (elt keys (1- (length keys))))
                nil))
  (let* ((arg (and current-prefix-arg
                   (prefix-numeric-value current-prefix-arg)))
         (number (find-number-at-point))
         (oargs (or (cdr (assoc key operate-on-number-at-point-alist))
                    (error "Unknown operator: %c" key)))
         (defargs (nth 0 oargs))
         (defarg (car defargs))
         (func (nth 1 oargs))
         (plist (nthcdr 2 oargs))
         (display (or (plist-get plist :display) (string key)))
         (args (cond ((null defargs)
                      nil)
                     ((and (numberp defarg)
                           arg)
                      (list arg))
                     ((or read-args
                          (plist-get plist :read))
                      (let* ((prompt (format "Insert %s %s " number display))
                             (input (if (numberp defarg)
                                        (read-number prompt defarg)
                                      (read-string prompt nil nil
                                                   defarg))))
                        (list input)))
                     (t
                      defargs))))
    (apply-to-number-at-point func args plist)))

;;;###autoload
(defun operate-on-number-at-point (&optional arg)
  "Operate on number at point.

The kind of operation to perform is specified by the following
key typed.

An optional number ARG becomes a counter operand to the number at
point for the operation if applicable."
  (interactive "*p")
  (let* ((number (find-number-at-point))
         (key (read-char (format "Apply on %s:" number) t)))
    (apply-operation-to-number-at-point key t)))

(provide 'operate-on-number)

;;; operate-on-number.el ends here
