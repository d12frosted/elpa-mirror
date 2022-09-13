;;; walkclj.el --- Manipulate Clojure parse trees -*- lexical-binding: t -*-
;;
;; Filename: walkclj.el
;; Author: Arne Brasseur
;; Maintainer: Arne Brasseur
;; Created: Mi Jul 18 09:39:10 2018 (+0200)
;; Version: 0.2.0
;; Package-Requires: ((emacs "25") (parseclj "0.1.0") (treepy "0.1.0") (a "1.0.0"))
;; URL: https://github.com/plexus/walkclj
;; Keywords: languages
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; A complementary library to parseclj, providing ways to traverse parse trees
;; as if they were s-expressions, as well as providing higher level
;; interpretations of parsed data.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Copyright (C) 2018  Arne Brasseur
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'treepy)
(require 'parseclj)
(require 'cl-lib)
(require 'a)

(eval-and-compile
  (defvar walkclj-function-names '(ffirst
                                   first
                                   last
                                   list-p
                                   list?
                                   meta
                                   name
                                   second
                                   symbol?
                                   symbol-p?
                                   unwrap-meta)
    "Names that are recognized inside walkclj-do and rewritten to be
walkclj- prefixed.")

  (defun walkclj--update-predicate-suffix (sym)
    "Change a symbol SYM that ends in `?' in one that ends in -p."
    (let ((s (symbol-name sym)))
      (if (equal "?" (substring s (1- (length s))) )
          (intern (concat (substring s 0 (1- (length s))) "-p"))
        sym))))

(defmacro walkclj-do (&rest body)
  "Evaluate BODY with auto-prefixing.

All symbols in the BODY that have a corresponding walkclj-
prefixed version are replaced by their prefixed version."

  (cons 'progn
        (treepy-postwalk (lambda (x)
                           (cond
                            ((member x walkclj-function-names)
                             (intern (concat "walkclj-" (symbol-name (walkclj--update-predicate-suffix x)))))

                            ((and (listp x)
                                  (keywordp (car x)))
                             (cl-list* 'a-get (cadr x) (car x) (cddr x)))

                            (t x)))
                         body)))

(defun walkclj-meta (form)
  "Return the metadata of FORM."
  (if (eq :with-meta (parseclj-ast-node-type form))
      (car (a-get form :children))
    form))

(defun walkclj-unwrap-meta (form)
  "Strip FORM of its metadata.

Nodes with metadata as parsed with a wrapping :with-meta node,
return the inner node if this is the case."
  (if (eq :with-meta (parseclj-ast-node-type form))
      (cadr (a-get form :children))
    form))

(defun walkclj-first (form)
  "Return the first child of FORM."
  (if-let (children (a-get form :children))
      (car children)
    nil))

(defun walkclj-second (form)
  "Return the second child of FORM."
  (if-let (children (a-get form :children))
      (cadr children)
    nil))

(defun walkclj-ffirst (form)
  "Same as (first (first FORM))."
  (walkclj-do (first (first form))))

(defun walkclj-list-p (form)
  "Does FORM represent a :list node?"
  (eq (parseclj-ast-node-type form) :list))

(defalias 'walkclj-list? 'walkclj-list-p)

(defun walkclj-symbol-p (form)
  "Does FORM represent a :symbol node?"
  (eq (parseclj-ast-node-type form) :symbol))

(defalias 'walkclj-symbol? 'walkclj-symbol-p)

(defun walkclj-name (form)
  "Return the name of FORM.

FORM has to be a string, symbol, or keyword."
  (cl-case (parseclj-ast-node-type form)
    (:string (a-get form :value))
    (:symbol (a-get form :form))
    (:keyword (substring (a-get form :form) 1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun walkclj-current-ns ()
  "Return the Clojure namespace name of the current buffer."
  (ignore-errors
    (save-excursion
      (goto-char 1)
      (let ((ns-form (parseclj-parse-clojure :read-one t)))
        (walkclj-do
         (when (and (list? ns-form) (eq 'ns (a-get (first ns-form) :value)))
           (name (unwrap-meta (second ns-form)))))))))

(provide 'walkclj)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; walkclj.el ends here
