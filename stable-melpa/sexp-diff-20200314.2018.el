;;; sexp-diff.el --- Diff sexps based on Levenshtein-like edit distance  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Xu Chunyang

;; Author: Xu Chunyang
;; Homepage: https://github.com/xuchunyang/sexp-diff.el
;; Package-Requires: ((emacs "25"))
;; Package-Version: 20200314.2018
;; Package-Commit: 4fea80f7b04c64b160a95bdc9d6de68c71096706
;; Keywords: lisp
;; Version: 0.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides an S-expression-aware diffing tool based on
;; Levenshtein-like tree edit distance.
;;
;; Ported directly from https://docs.racket-lang.org/sexp-diff/index.html

;;; Code:

(require 'cl-lib)                    ; to silence Emacs 27 byte compile warnings

(defun sexp-diff--tree-size (tree)
  "Computes the number of atoms contained in TREE."
  (if (consp tree)
      (apply #'+ 1 (mapcar #'sexp-diff--tree-size tree))
    1))

(cl-defstruct (sexp-diff--edit-record
               (:constructor sexp-diff--edit-record-create (edit-distance))
               (:copier nil))
  edit-distance)

(cl-defstruct (sexp-diff--unchanged-record
               (:constructor sexp-diff--unchanged-record-create (edit-distance change))
               (:copier nil)
               (:include sexp-diff--edit-record))
  change)

(defun sexp-diff--unchanged-record-make (change)
  "Make `sexp-diff--unchanged-record' object from CHANGE."
  (sexp-diff--unchanged-record-create (sexp-diff--tree-size change) change))

(cl-defstruct (sexp-diff--deletion-record
               (:constructor sexp-diff--deletion-record-create (edit-distance change))
               (:copier nil)
               (:include sexp-diff--edit-record))
  change)

(defun sexp-diff--deletion-record-make (change)
  "Make `sexp-diff--deletion-record' object from CHANGE."
  (sexp-diff--deletion-record-create (1+ (sexp-diff--tree-size change)) change))

(cl-defstruct (sexp-diff--insertion-record
               (:constructor sexp-diff--insertion-record-create (edit-distance change))
               (:copier nil)
               (:include sexp-diff--edit-record))
  change)

(defun sexp-diff--insertion-record-make (change)
  "Make `sexp-diff--insertion-record' object from CHANGE."
  (sexp-diff--insertion-record-create (1+ (sexp-diff--tree-size change)) change))

(cl-defstruct (sexp-diff--update-record
               (:constructor sexp-diff--update-record-create (edit-distance old new))
               (:copier nil)
               (:include sexp-diff--edit-record))
  old new)

(defun sexp-diff--update-record-make (old new)
  "Make a `sexp-diff--update-record' object from OLD and NEW."
  (sexp-diff--update-record-create (+ 1 (sexp-diff--tree-size old)
                                      1 (sexp-diff--tree-size new))
                                   old new))

(cl-defstruct (sexp-diff--compound-record
               (:constructor sexp-diff--compound-record-create (edit-distance changes))
               (:copier nil)
               (:include sexp-diff--edit-record))
  changes)

(defun sexp-diff--compound-record-make (changes)
  "Make a `sexp-diff--compound-record' object.
Argument CHANGES is a list of changes."
  (sexp-diff--compound-record-create
   (apply #'+ (mapcar #'sexp-diff--edit-record-edit-distance changes))
   changes))

(defun sexp-diff--compound-record-make-empty ()
  "Make a empty `sexp-diff--compound-record' object."
  (sexp-diff--compound-record-make '()))

(defun sexp-diff--compound-record-make-extend (r0 record)
  "Make a `sexp-diff--compound-record' from R0 and RECORD."
  (sexp-diff--compound-record-make (cons record (sexp-diff--get-change r0))))

(defun sexp-diff--get-change (record)
  "Get change from RECORD."
  (pcase record
    ((cl-struct sexp-diff--unchanged-record  change)  change)
    ((cl-struct sexp-diff--deletion-record   change)  change)
    ((cl-struct sexp-diff--insertion-record  change)  change)
    ((cl-struct sexp-diff--compound-record   changes) changes)))

(defun sexp-diff--render-difference (record old-marker new-marker)
  "Render difference in RECORD with OLD-MARKER and NEW-MARKER."
  (pcase record
    ((cl-struct sexp-diff--insertion-record  change) (list new-marker change))
    ((cl-struct sexp-diff--deletion-record   change) (list old-marker change))
    ((cl-struct sexp-diff--update-record    old new) (list old-marker old new-marker new))
    ((cl-struct sexp-diff--unchanged-record  change) (list change))
    ((cl-struct sexp-diff--compound-record  changes)
     (list
      (cl-loop for r in (reverse changes)
               append (sexp-diff--render-difference r old-marker new-marker))))))

(defun sexp-diff--min-edit (record &rest records)
  "Return record with minimum edit distance in RECORD and RECORDS."
  (cl-loop for r in (nreverse records)
           when (<= (sexp-diff--edit-record-edit-distance r)
                    (sexp-diff--edit-record-edit-distance record))
           do (setq record r)
           finally return record))

(defun sexp-diff--initial-distance (function lst)
  "Prepare initial data vectors for Levenshtein algorithm from LST.
Argument FUNCTION will be applied to each element of LST."
  (let ((seq (make-vector (1+ (length lst)) (sexp-diff--compound-record-make-empty))))
    (cl-loop for i from 0
             for elt in lst
             do (aset seq (1+ i)
                      (sexp-diff--compound-record-make-extend
                       (aref seq i)
                       (funcall function elt))))
    seq))

(defun sexp-diff--levenshtein-tree-edit (old-tree new-tree)
  "Calculate the minimal edits needed to transform OLD-TREE into NEW-TREE.
It minimizes the number of atoms in the result tree, also counting
edit conditionals."
  (cond
   ((equal old-tree new-tree)
    (sexp-diff--unchanged-record-make old-tree))
   ((not (and (consp old-tree) (consp new-tree)))
    (sexp-diff--update-record-make old-tree new-tree))
   (t
    (sexp-diff--min-edit
     (sexp-diff--update-record-make old-tree new-tree)
     (let* ((best-edit nil)
            (row (sexp-diff--initial-distance
                  #'sexp-diff--deletion-record-make
                  old-tree))
            (col (sexp-diff--initial-distance
                  #'sexp-diff--insertion-record-make
                  new-tree)))
       (cl-loop for new-part in new-tree
                for current in (cdr (append col nil))
                do
                (cl-loop for old-part in old-tree
                         for row-idx from 0
                         do
                         (setq best-edit
                               (sexp-diff--min-edit
                                (sexp-diff--compound-record-make-extend
                                 (aref row (1+ row-idx))
                                 (sexp-diff--insertion-record-make new-part))
                                (sexp-diff--compound-record-make-extend
                                 current
                                 (sexp-diff--deletion-record-make old-part))
                                (sexp-diff--compound-record-make-extend
                                 (aref row row-idx)
                                 (sexp-diff--levenshtein-tree-edit old-part new-part))))
                         (aset row row-idx current)
                         (setq current best-edit))
                (aset row (1- (length row)) best-edit))
       best-edit)))))

(cl-defun sexp-diff (old-tree new-tree &key (old-marker :old) (new-marker :new))
  "Compute a diff between OLD-TREE and NEW-TREE.
The diff minimizes the number of atoms in the result tree, also
counting inserted edit conditionals :new, :old."
  (sexp-diff--render-difference (sexp-diff--levenshtein-tree-edit old-tree new-tree)
                                old-marker new-marker))

(provide 'sexp-diff)
;;; sexp-diff.el ends here
