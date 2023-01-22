Table of Contents
_________________

1. Tail call optimization for Emacs.
2. How to Use?
.. 1. `recur-loop' / `recur-let'
.. 2. `recur-progv'
.. 3. `recur-defun'
3. License


[https://img.shields.io/github/tag/ROCKTAKEY/recur.svg?style=flat-square]
[https://img.shields.io/github/license/ROCKTAKEY/recur.svg?style=flat-square]
[https://img.shields.io/codecov/c/github/ROCKTAKEY/recur.svg?style=flat-square]
[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/recur/CI.yml.svg?style=flat-square]
[file:https://melpa.org/packages/recur-badge.svg]


[https://img.shields.io/github/tag/ROCKTAKEY/recur.svg?style=flat-square]
<https://github.com/ROCKTAKEY/recur>

[https://img.shields.io/github/license/ROCKTAKEY/recur.svg?style=flat-square]
<file:LICENSE>

[https://img.shields.io/codecov/c/github/ROCKTAKEY/recur.svg?style=flat-square]
<https://codecov.io/gh/ROCKTAKEY/recur?branch=master>

[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/recur/CI.yml.svg?style=flat-square]
<https://github.com/ROCKTAKEY/recur/actions>

[file:https://melpa.org/packages/recur-badge.svg]
<https://melpa.org/#/recur>


1 Tail call optimization for Emacs.
===================================

  `recur' means recursive call (like clojure).  All `recur' must be
  called on tail.
  ,----
  | (recur-loop                             ;Same as `recur-let'
  |     ((x 5)
  |      (y 1))
  |   (if (eq x 0)
  |       y
  |     (recur (1- x) (* x y))))
  | ;; => 120
  |
  | (recur-progv '(x y) '(5 1)
  |   (if (eq x 0)
  |       y
  |     (recur (1- x) (* x y))))
  | ;; => 120
  |
  | (recur-defun factorial (x &optional y)
  |   (setq y (or y 1))
  |   (if (eq x 0)
  |       y
  |     (recur (1- x) (* x y))))
  | ;; => factorial
  |
  | (factorial 5 1)
  | ;; => 120
  |
  | (factorial 5)
  | ;; => 120
  |
  | (recur-defun sum (init &rest list)
  |   (if list
  |       (recur (+ init (car list))
  |              (cdr list))
  |     init))
  | ;; => sum
  |
  | (sum 1 2 3 4 5)
  | ;; 15
  |
  `----


2 How to Use?
=============

2.1 `recur-loop' / `recur-let'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Recursively callable `let'.  Similar to `loop' in clojure.  This is
  same as `recur-progv', except using `BINDINGS' like `let' instead of
  `SYMBOLS' and `INITVALUES'.  `BODY' is evaluated with variables set by
  `BINDINGS'.

  Note that `recur' MUST be tail recursion and this macro optimize tail
  call.


2.2 `recur-progv'
~~~~~~~~~~~~~~~~~

  Recursively callable `cl-progv'.  `SYMBOLS', `INITVALUES' (as
  `VALUES'), and `BODY' are same as arguments of `cl-progv'.  In
  addition, you can use function `recur' in `BODY' form.  This function
  take arguments same number as length of `SYMBOLS', and evaluate `BODY'
  form with `SYMBOLS' bounded by each value of arguments.

  Note that `recur' MUST be tail recursion and this macro optimize tail
  call.


2.3 `recur-defun'
~~~~~~~~~~~~~~~~~

  Define function with tail call optimization.  `NAME', `ARGLIST',
  `DOCSTRING' and `BODY' is same as arguments of `defun'.  `recur' in
  `BODY' calls the function named NAME itself with arguments.  `recur'
  cannot recieve variable length arguments, so you must pass one list
  even as `&rest' argument.

  Note that `recur' MUST be tail recursion and this macro optimize tail
  call.


3 License
=========

  This package is licensed by GPLv3. See [LICENSE].


[LICENSE] <file:LICENSE>
