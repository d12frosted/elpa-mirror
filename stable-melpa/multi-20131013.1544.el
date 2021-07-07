;;; multi.el --- Clojure-style multi-methods for emacs lisp -*- lexical-binding: t -*-

;; Copyright (c) 2013 Christina Whyte <kurisu.whyte@gmail.com>

;; Version: 2.0.1
;; Package-Version: 20131013.1544
;; Package-Commit: 0987ab71692717ed457cb3984de184db9185806d
;; Package-Requires: ((emacs "24"))
;; Keywords: multimethod generic predicate dispatch
;; Author: Christina Whyte <kurisu.whyte@gmail.com>
;; URL: http://github.com/kurisuwhyte/emacs-multi

;; This file is not part of GNU Emacs.

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.


;;; Commentary

;; See README.md (or http://github.com/kurisuwhyte/emacs-multi#readme)

;;; Code:

;;;; State ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar multi/-method-branches (make-hash-table)
  "A dictionary of dictionaries of branches.

Type: { Symbol → { A → (A... → B) }}

This holds the mappings of names to a mappings of premises to lambdas,
which allows a relatively efficient dispatching O(2) when applying the
multi-method.")


(defvar multi/-method-fallbacks (make-hash-table)
  "A dictionary of fallbacks for each multi-method.

Type: { Symbold → (A... → B) }

This holds mappings of names to fallback method branches, which are
invoked in case none of the premises for the defined branches match.")


;;;; API ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmacro defmulti (name arguments &optional docstring &rest forms)
  "Defines a new multi-method and a dispatch function."
  (declare (doc-string 3)
           (debug (&define name (&rest arg) [&optional stringp] def-body))
           (indent defun))
  `(progn
     (defun ,name (&rest args)
       ,(if (stringp docstring) docstring (prog1 nil (push docstring forms)))
       (apply (multi/-dispatch-with ',name (lambda ,arguments ,@forms))
        args))
     (multi/-make-multi-method ',name)))


(defmacro defmulti-method (name premise arguments &rest forms)
  "Adds a branch to a previously-defined multi-method."
  (declare (debug (&define name sexp (&rest arg) def-body))
           (indent defun))
  `(multi/-make-multi-method-branch ',name ,premise
            (lambda ,arguments ,@forms)))


(defmacro defmulti-method-fallback (name arguments &rest forms)
  "Adds a fallback branch to a previously-defined multi-method.

The fallback branch will be applied if none of the premises defined
for the branches in a multi-method match the dispatch value."
  `(multi/-make-multi-method-fallback ',name (lambda ,arguments ,@forms)))


(defun multi-remove-method (name premise)
  "Removes the branch with the given premise from the multi-method."
  (remhash premise (gethash name multi/-method-branches)))


(defun multi-remove-method-fallback (name)
  "Removes the defined fallback branch for the multi-method."
  (remhash name multi/-method-fallbacks))


;;;; Helper functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun multi/-make-multi-method (name)
  (puthash name (make-hash-table :test 'equal)
     multi/-method-branches))


(defun multi/-make-multi-method-branch (name premise lambda)
  (puthash premise lambda
     (gethash name multi/-method-branches)))


(defun multi/-make-multi-method-fallback (name lambda)
  (puthash name lambda multi/-method-fallbacks))


(defun multi/-dispatch-with (name f)
  (lambda (&rest args)
    (let* ((premise (apply f args))
     (method  (gethash premise (gethash name multi/-method-branches))))
      (if method (apply method args)
  (apply (gethash name multi/-method-fallbacks) args)))))


;;;; Emacs stuff ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(eval-after-load "lisp-mode"
  '(progn
     (font-lock-add-keywords 'emacs-lisp-mode
                             '(("(\\(defmulti\\|defmulti-method\\|defmulti-method-fallback\\)\\(?:\\s-\\)+\\(\\_<.*?\\_>\\)"
                                (1 font-lock-keyword-face)
                                (2 font-lock-function-name-face))))))


(provide 'multi)
;;; multi.el ends here
