;;; loopy-dash.el --- Dash destructuring for `loopy' -*- lexical-binding: t; -*-

;; Copyright (c) 2021 Earl Hyatt

;; Author: Earl Hyatt
;; Created: February 2021
;; URL: https://github.com/okamsn/loopy
;; Package-Version: 20211020.157
;; Package-Commit: 49efa7e59deaa2a0385e420b18df905a2328f9c4
;; Version: 0.9.1
;; Package-Requires: ((emacs "25.1") (loopy "0.9.1") (dash "2.19"))
;; Keywords: extensions
;; LocalWords:  Loopy's emacs

;;; Disclaimer:
;; This file is not part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package is an optional extension for the package `loopy'.
;;
;; The `loopy' macro is used to generate code for a loop, similar to `cl-loop'.
;; Unlike `cl-loop', `loopy' uses symbolic expressions instead of "clauses".
;;
;; This package provides a way to use the destructuring features of the Dash
;; library in `loopy'.
;;
;;     ;; => ((1 4)            coll1
;;     ;;     ((2 3) (5 6))    whole
;;     ;;     (2 5)            x
;;     ;;     (3 6))           y
;;     (require 'loopy-dash)
;;     (loopy (flag dash)
;;            (list (i j) '((1 (2 3)) (4 (5 6))))
;;            (collect coll1 i)
;;            (collect (whole &as x y) j)
;;            (finally-return coll1 whole x y))
;;
;; For more information, including the full list of loop commands and how to
;; extend the macro, see the main package's comprehensive Info documentation
;; under the Info node `(loopy)'.

;;; Code:
(require 'loopy)
(require 'loopy-misc)
(require 'loopy-vars)
(require 'dash)
(require 'cl-lib)

(defun loopy-dash--enable-flag-dash ()
  "Make this `loopy' loop use Dash destructuring."
  (setq
   loopy--destructuring-for-iteration-function
   #'loopy-dash--destructure-for-iteration
   loopy--destructuring-for-with-vars-function
   #'loopy-dash--destructure-for-with-vars
   loopy--destructuring-accumulation-parser
   #'loopy-dash--parse-destructuring-accumulation-command))

(defun loopy-dash--disable-flag-dash ()
  "Make this `loopy' loop use Dash destructuring."
  (if (eq loopy--destructuring-for-iteration-function
          #'loopy-dash--destructure-for-iteration)
      (setq loopy--destructuring-for-iteration-function
            #'loopy--destructure-for-iteration-default))
  (if (eq loopy--destructuring-for-with-vars-function
          #'loopy-dash--destructure-for-with-vars)
      (setq loopy--destructuring-for-with-vars-function
            #'loopy--destructure-for-with-vars-default))
  (if (eq loopy--destructuring-accumulation-parser
          #'loopy-dash--parse-destructuring-accumulation-command)
      (setq loopy--destructuring-accumulation-parser
            #'loopy--parse-destructuring-accumulation-command)))

(add-to-list 'loopy--flag-settings (cons 'dash #'loopy-dash--enable-flag-dash))
(add-to-list 'loopy--flag-settings (cons '+dash #'loopy-dash--enable-flag-dash))
(add-to-list 'loopy--flag-settings (cons '-dash #'loopy-dash--disable-flag-dash))

;;;; The actual functions:
(defun loopy-dash--destructure-for-with-vars (bindings)
  "Return a way to destructure BINDINGS as if by `-let*'.

Returns a list of two elements:
1. The symbol `-let*'.
2. A new list of bindings."
  (list '-let* bindings))

(defun loopy-dash--destructure-for-iteration (var val)
  "Destructure VAL according to VAR as if by `-let'.

Returns a list.  The elements are:
1. An expression which binds the variables in VAR to the values
   in VAL.
2. A list of variables which exist outside of this expression and
   need to be `let'-bound."
  (let ((bindings (dash--match var val)))
    (list (cons 'setq (apply #'append bindings))
          ;; Note: This includes the named variables and the needed generated
          ;;       variables.
          (mapcar #'car bindings))))

(cl-defun loopy-dash--parse-destructuring-accumulation-command
    ((name var val &rest args))
  "Parse the accumulation loop commands, like `collect', `append', etc.

NAME is the name of the command.  VAR is a variable name.
VAL is a value."
  (let ((old-destructuring (dash--match var val))
        (new-destructuring)
        (old-new-map))
    ;; We previously tried to swap out variables in the argument list, but Dash
    ;; uses look-ahead to derive meaning.  This caused problems.  Therefore, it
    ;; is probably better to rely on the regular naming scheme produced by
    ;; `dash--match-make-source-symbol'.
    (dolist (binding old-destructuring)
      (let ((var (car binding))
            (val (car (cdr-safe binding))))
        (if (string-match-p (rx "--dash-source-" (1+ digit) "--")
                            (symbol-name var))
            (push binding new-destructuring)
          (let ((new-var (gensym (format "loopy-copy-%s" var))))
            (push (list new-var val) new-destructuring)
            (push (cons var new-var) old-new-map)))))
    ;; Correct the order.
    (setq new-destructuring (reverse new-destructuring))
    `(,@(mapcar (lambda (x) `(loopy--accumulation-vars (,x nil)))
                (cl-union (mapcar #'car old-destructuring)
                          (mapcar #'car new-destructuring)))
      (loopy--main-body (setq ,@(apply #'append new-destructuring)))
      ,@(mapcan (pcase-lambda (`(,old-name . ,new-name))
                  (loopy--parse-loop-command
                   `(,name ,old-name ,new-name ,@args)))
                old-new-map))))

(provide 'loopy-dash)
;;; loopy-dash.el ends here
