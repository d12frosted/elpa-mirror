;;; ptree.el --- Property tree data structure -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Alpha Catharsis

;; Author: Alpha Catharsis <alpha.catharsis@gmail.com>
;; Maintainer: Alpha Catharsis <alpha.catharsis@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20221106.1649
;; Package-Commit: 23cb9093f99b9869606f8d54fa5c45ea35fcc789
;; Keywords: lisp
;; URL: https://github.com/alpha-catharsis/ptree
;; Package-Requires: ((emacs "25.1"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; ptree provides a tree data structure for storing properties.
;; The package documentation is available here:
;;
;; https://github.com/alpha-catharsis/ptree
;;
;; Please report bugs, requests and suggestions to
;; Alpha Catharsis <alpha.catharsis@gmail.com> or on Github.

;;; Code:

;; Errors definition

(define-error 'ptree-not-a-category "A property as been passed to a function \
expecting a category")

(define-error 'ptree-not-a-property "A category as been passed to a function \
expecting a property")

(define-error 'ptree-node-already-existing "Tried to create an existing node")

(define-error 'ptree-node-not-existing "Tried to modify a non existing node")

;; Property tree construction

(defun ptree-empty ()
  "Create an empty property tree."
  (list nil))

;; Node predicates

(defun ptree-category-p (node)
  "Check if NODE is a category of the property tree.
The function returns 't if NODE is a category, otherwise 'nil."
  (not (car node)))

(defun ptree-property-p (node)
  "Check if NODE is a property of the property tree.
The function returns 't if NODE is a property, otherwise 'nil."
  (not (null (car node))))

;; Node attributes

(defun ptree-property-value (node)
  "Get the property value associated with NODE.
If NODE is a category, 'ptree-not-a-property error is signaled."
  (if (ptree-property-p node)
      (cdr node)
    (signal 'ptree-not-a-property node)))

(defun ptree-property-type (node)
  "Get the property value associated with NODE.
If NODE is a category, 'ptree-not-a-property error is signaled."
  (if (ptree-property-p node)
      (car node)
    (signal 'ptree-not-a-property node)))

(defun ptree-set-property (node value &optional type)
  "Set VALUE and TYPE for property at NODE.
If NODE is a category, 'ptree-not-a-property error is signaled."
  (if (ptree-category-p node)
      (signal 'ptree-not-a-property node)
    (when type
      (setcar node type))
    (setcdr node value)))

(defun ptree-child-nodes-num (node)
  "Get the number of child nodes of NODE.
If NODE is a property, 0 is returned."
  (if (car node)
      0
    (/ (length (cdr node)) 2)))

;; Node retrieval

(defun ptree-child-node-at-index (node index)
  "Get the child node of NODE at position INDEX.
If NODE is a property or if INDEX is out of range, 'nil is returned"
  (if (car node)
      nil
    (nth (1+ (* index 2)) (cdr node))))

(defun ptree-child-node-with-tag (node tag)
  "Get child node of NODE with TAG.
If NODE is a property or if such child node does not exist, 'nil is returned."
  (ptree--child-node node tag))

;; Nodes construction

(defun ptree-add-category (node tag)
  "Add a category with TAG as child of NODE.
If NODE is a property, 'ptree-not-a-category error is signaled.
If a child node with the specified tag already exists,
'ptree-node-already-existing error is signaled.
The functions returns the created category."
  (let ((res (list nil)))
    (ptree--add-child-node node tag res nil)
    res))

(defun ptree-add-property (node tag value &optional type)
  "Add a property with TAG, VALUE and TYPE as child of NODE.
If TYPE is not provided, type is set to 'generic.
If NODE is a property, 'ptree-not-a-category error is signaled.
If a child node with the specified tag already exists,
'ptree-node-already-existing error is signaled.
The functions returns the created property."
  (unless type
    (setq type 'generic))
  (let ((res (cons type value)))
    (ptree--add-child-node node tag res nil)
    res))

;; Node attachment

(defun ptree-attach-node (node tag child)
  "Attach CHILD node to NODE with TAG.
If NODE is a property, 'ptree-not-a-category error is signaled.
If a child node with the specified tag already exists,
'ptree-node-already-existing error is signaled."
  (ptree--add-child-node node tag child nil))

;; Node deletion

(defun ptree-delete-child-node (node tag)
  "Delete child node of NODE with TAG.
If NODE is a property, 'ptree-not-a-category error is signaled.
If such child node does not exist, 'ptree-node-not-existing error is raised."
  (ptree--delete-child-node node tag))

;; Convenience functions

(defun ptree-node-at-path (node path)
  "Get the descendant of NODE at PATH.
PATH is the list of tags that shall be followed to reach the descendant node.
If only one tag has to be specified, it is possible to set PATH to the value
of the tag instead of passing PATH as a list with a single tag.
If PATH is nil, the descendant of NODE is NODE itself.
If descendant node at PATH does not exist, the function returns 'nil."
  (unless (listp path)
    (setq path (list path)))
  (ptree--node-at-path node path))

(defun ptree-value-at-path (node path)
  "Get the value of descendat property of NODE at PATH.
PATH is the list of tags that shall be followed to reach the descendant node.
If only one tag has to be specified, it is possible to set PATH to the value
of the tag instead of passing PATH as a list with a single tag.
If PATH is nil, the descendant of NODE is NODE itself.
If descendant node at PATH does not exist or if it is not a property,
'not-found is returned."
  (setq node (ptree-node-at-path node path))
  (if (or (not node) (ptree-category-p node))
      'not-found
    (ptree-property-value node)))

(defun ptree-write-categories-at-path (node path &rest tags)
  "Create categories as child nodes of NODE at PATH.
TAGS the list of tags of the categories to be created.
PATH is the list of tags that shall be followed to reach the descendant node.
If only one tag has to be specified, it is possible to set PATH to the value
of the tag instead of passing PATH as a list with a single tag.
If PATH is nil, the descendant of NODE is NODE itself.
If a node in the path does not exist, it is created.
If a node in the path is a property, it is turned into a catagory.
If a tag in TAGS refers to an existing property, it is turned into a
category.
The function returns the last child node created."
  (unless (listp path)
    (setq path (list path)))
  (setq node (ptree--write-path node path))
  (let ((res nil))
    (while tags
      (setq res (ptree--add-child-node node (car tags) (list nil) t))
      (setq tags (cdr tags)))
    res))

(defun ptree-write-properties-at-path (node path &rest props-data)
  "Create properties as child nodes of NODE at PATH.
PROPS-DATA is a list of property data items. Each property data item can have
the format (tag . value) or (tag value . type). In the latter case, the
property value is set to 'generic.
PATH is the list of tags that shall be followed to reach the descendant node.
If only one tag has to be specified, it is possible to set PATH to the value
of the tag instead of passing PATH as a list with a single tag.
If PATH is nil, the descendant of NODE is NODE itself.
If a node in the path does not exist, it is created.
If a node in the path is a property, it is turned into a catagory.
If a tag in PROP-DATA refers to an existing category, it is turned into a
property.
The function returns the last child node created."
  (unless (listp path)
    (setq path (list path)))
  (setq node (ptree--write-path node path))
  (let ((res nil))
    (while props-data
      (let ((prop-data (car props-data)))
        (if (consp (cdr prop-data))
            (setq res (cons (cddr prop-data) (cadr prop-data)))
          (setq res (cons 'generic (cdr prop-data))))
        (ptree--add-child-node node (car prop-data) res t)
        (setq props-data (cdr props-data))))
    res))

;; Iterator management

(defun ptree-iter (node)
  "Create an iterator associated with NODE.
NODE represent the initial node for the iterator.
The iterator can only move down to the child nodes of the initial node.
The iterator cannot move to the parent or sibling nodes of the initial node."
  (list nil node nil nil))

(defun ptree-iter-node (iterator)
  "Get the node associated with ITERATOR."
  (cadr iterator))

(defun ptree-iter-category-p (iterator)
  "Check if node associated with ITERATOR is a category of the property tree.
The function returns 't if the node is a category, otherwise 'nil."
  (ptree-category-p (cadr iterator)))

(defun ptree-iter-property-p (iterator)
  "Check if node associated with ITERATOR is a property of the property tree.
The function returns 't if the node is a property, otherwise 'nil."
  (ptree-property-p (cadr iterator)))

(defun ptree-iter-value (iterator)
  "Return the value of the property associated with ITERATOR.
If the node associated with ITERATOR is a category,
 'ptree-not-a-property error is signaled."
  (ptree-property-value (cadr iterator)))

(defun ptree-iter-type (iterator)
  "Return the type of the property associated with ITERATOR.
If the node associated with ITERATOR is a category,
'ptree-not-a-property error is signaled."
  (ptree-property-type (cadr iterator)))

(defun ptree-iter-set-property (iterator value &optional type)
  "Set VALUE and TYPE for property associated with ITERATOR.
If the node asociated with ITERATOR is a category,
'ptree-not-a-property error is signaled."
  (ptree-set-property (cadr iterator) value type))

(defun ptree-iter-tag (iterator)
  "Provides the tag of the node associated with ITERATOR.
If the iterator is associated with the root node of the property tree 'nil
is returned."
  (car iterator))

(defun ptree-iter-path (iterator)
  "Provides the path of the node associated with ITERATOR.
The path is reported with respect to the iterator initial node.
If the iterator is on the initial node, 'nil is returned."
  (let* ((path nil)
         (parents (caddr iterator)))
    (when (car iterator)
      (setq path (list (car iterator))))
    (while (caar parents)
      (setq path (cons (caar parents) path))
      (setq parents (cdr parents)))
    path))

(defun ptree-iter-has-child (iterator)
  "Check if the node associated with ITERATOR has a child node.
The function returns 't if a child node exists, otherwise 'nil."
  (let ((node (cadr iterator)))
    (and (ptree-category-p node) (consp (cdr node)))))

(defun ptree-iter-has-parent (iterator)
  "Check if the node associated with ITERATOR has a parent node.
The function returns 't if a parent node exists, otherwise 'nil."
  (consp (caddr iterator)))

(defun ptree-iter-has-next (iterator)
  "Check if the node associated with ITERATOR has a next sibling node.
The function returns 't if a next sibling node exists, otherwise 'nil."
  (consp (cadddr iterator)))

(defun ptree-iter-has-previous (iterator)
  "Check if the node associated with ITERATOR has a previous sibling node.
The function returns 't if a previous sibling node exists, otherwise 'nil."
  (consp (cddddr iterator)))

(defun ptree-iter-down (iterator &optional steps)
  "Move ITERATOR down the property tree by STEPS.
If STEPS is not specified, a single step is performed.
If it is not possible to perform a step because the node is a property or
because it has no child nodes, the function stops.
The function returns the number of steps not performed"
  (unless steps
    (setq steps 1))
  (while (and (> steps 0) (ptree--iter-step-down iterator))
    (setq steps (- steps 1)))
  steps)

(defun ptree-iter-up (iterator &optional steps)
  "Move ITERATOR up the property tree by STEPS.
If STEPS is not specified, a single step is performed.
If it is not possible to perform a step because the node is a property or
because it is the iterator initial node, the function stops.
The function returns the number of steps not performed"
  (unless steps
    (setq steps 1))
  (while (and (> steps 0) (ptree--iter-step-up iterator))
    (setq steps (- steps 1)))
  steps)

(defun ptree-iter-next (iterator &optional steps)
  "Move ITERATOR to the next sibling node of the property tree by STEPS.
If STEPS is not specified, a single step is performed.
If it is not possible to perform a step because the node is a property or
because it has no child nodes, the function stops.
The function returns the number of steps not performed"
  (unless steps
    (setq steps 1))
  (while (and (> steps 0) (ptree--iter-step-next iterator))
    (setq steps (- steps 1)))
  steps)

(defun ptree-iter-previous (iterator &optional steps)
  "Move ITERATOR to the previous sibling node of the property tree by STEPS.
If STEPS is not specified, a single step is performed.
If it is not possible to perform a step because the node is a property or
because it has no child nodes, the function stops.
The function returns the number of steps not performed"
  (unless steps
    (setq steps 1))
  (while (and (> steps 0) (ptree--iter-step-previous iterator))
    (setq steps (- steps 1)))
  steps)

(defun ptree-iter-move-with-tag (iterator tag)
  "Move ITERATOR to the child node of its associtated node with TAG.
If such node does not exist, the iterator is not moved and 'nil is returned,
otherwise 't is returned."
  (if (not (ptree-iter-down iterator))
      nil
      (while (and (not (equal (ptree-iter-tag iterator) tag))
                  (= (ptree-iter-next iterator) 0)))
      (if (equal (ptree-iter-tag iterator) tag)
          t
        (ptree-iter-up iterator)
        nil)))

(defun ptree-iter-add-property (iterator tag value &optional type)
  "Add a property as child of node associated with ITERATOR.
The property has TAG, VALUE and TYPE specified through the input parameters.
If TYPE is not provided, type is set to 'generic.
If NODE is a property, 'ptree-not-a-category error is signaled.
If a child node with the specified tag already exists,
'ptree-node-already-existing error is signaled.
The functions returns the created property."
  (ptree-add-property (cadr iterator) tag value type))

(defun ptree-iter-add-category (iterator tag)
  "Add a category with TAG as child of the node associated with ITERATOR.
If NODE is a property, 'ptree-not-a-category error is signaled.
If a child node with the specified tag already exists,
'ptree-node-already-existing error is signaled.
The functions returns the created category."
  (ptree-add-category (cadr iterator) tag))

(defun ptree-iter-add-category-and-move (iterator tag)
  "Add a category as child of the node associated with ITERATOR and move to it.
The category has TAG specified through the input parameters.
If NODE is a property, 'ptree-not-a-category error is signaled.
If a child node with the specified tag already exists,
'ptree-node-already-existing error is signaled."
  (ptree-add-category (cadr iterator) tag)
  (ptree-iter-move-with-tag iterator tag))

(defun ptree-iter-delete-node (iterator)
  "Delete the node associated with ITERATOR.
If ITERATOR is pointing to its initial node, deletion is not performed.
If the node is deleted ITERATOR is move to its parent node and 't is
returned, otherwise 'nil is returned."
  (if (not (caddr iterator))
      nil
    (let ((tag (ptree-iter-tag iterator)))
      (ptree-iter-up iterator)
      (ptree-delete-child-node (cadr iterator) tag)
      t)))

;; String conversion

(defun ptree-to-string (node &optional indent)
  "Convert NODE to string using INDENT level.
If INDENT is not specified, indentation level is set to 4."
  (unless indent
    (setq indent 4))
  (let ((res "")
        (iter (ptree-iter node))
        (level 0))
    (when (eq (ptree-iter-down iter) 0)
      (while (not (eq (ptree-iter-node iter) node))
        (setq res (concat res (ptree--node-to-string (ptree-iter-tag iter)
                               (ptree-iter-node iter) level indent)))
        (if (eq (ptree-iter-down iter) 0)
            (setq level (+ level 1))
          (unless (eq (ptree-iter-next iter) 0)
            (let ((in-progress t))
              (while in-progress
                (if (eq (ptree-iter-up iter) 0)
                    (setq level (- level 1))
                  (setq in-progress nil))
                (when (eq (ptree-iter-next iter) 0)
                  (setq in-progress nil))))))))
    res))

;; Internal functions

(defun ptree--compare-tags (ltag rtag)
  "Copares LTAG with RTAG.
Integers precede symbols, that precede strings.
Integers and strings are compared using standard comparison functions.
Symbols are converted to strings and then compared using string comparison
functions.
The comparison returns 'lt if LTAG is lower than RTAG, 'eq if LTAG is
equal to RTAG, 'gt if LTAG is greater than RTAG."
  (cond ((integerp ltag)
         (cond ((integerp rtag)
                (cond ((< ltag rtag) 'lt)
                      ((= ltag rtag) 'eq)
                      (t 'gt)))
               (t 'lt)))
        ((symbolp ltag)
         (cond ((integerp rtag) 'gt)
               ((symbolp rtag)
                (let ((lstr (symbol-name ltag))
                      (rstr (symbol-name rtag)))
                  (cond ((string< lstr rstr) 'lt)
                        ((string= lstr rstr) 'eq)
                        (t 'gt))))
               (t 'lt)))
        (t (cond ((integerp rtag) 'gt)
                 ((symbolp rtag) 'gt)
                 (t (cond ((string< ltag rtag) 'lt)
                          ((string= ltag rtag) 'eq)
                          (t 'gt)))))))

(defun ptree--child-node (node tag)
  "Get child node of NODE with TAG.
If NODE is a property or if such child node does not exist, 'nil is returned."
    (if (car node)
        nil
      (let* ((res nil)
             (cns (cdr node))
             (cn (car cns)))
        (while (and cn (not res))
          (let ((cmp (ptree--compare-tags tag cn)))
            (cond ((eq cmp 'eq) (setq res (cadr cns)))
                  ((eq cmp 'ge) (setq cn nil))
                  (t
                   (setq cns (cddr cns))
                   (setq cn (car cns))))))
        res)))

(defun ptree--node-at-path (node path)
  "Get the descendant of NODE at PATH.
If a node in the PATH is a property, 'ptree-not-a-category error is signaled.
If the descendant node does not exist, 'nil is returned."
  (while (and node path)
    (let ((child (ptree--child-node node (car path))))
      (setq path (cdr path))
      (setq node child)))
  node)

(defun ptree--add-child-node (node tag child overwrite)
  "Add the CHILD node with TAG to NODE.
If NODE is a property and OVERWRITE is not set, 'ptree-not-a-category error is
signaled. If OVERWRITE is set the property is turned into a category.
If the node already exists and OVERWRITE is not set,
'ptree-node-already-existing error is signaled. If OVERWRITE is set and the
child node is overwritten if both the CHILD node and existing node are
categories. In such a case, the existing node is not modified.
The function returns the child node of NODE with TAG."
  (when (ptree-property-p node)
    (if overwrite
        (progn
          (setcar node nil)
          (setcdr node (list tag child)))
      (signal 'ptree-not-a-category node)))
  (if (not (cdr node))
      (setcdr node (list tag child))
    (let* ((cns (cdr node))
           (prev-cns nil)
           (in-progress t))
      (while in-progress
        (let ((cmp (ptree--compare-tags tag (car cns))))
          (cond ((eq cmp 'gt)
                 (if (cddr cns)
                     (progn
                       (setq prev-cns cns)
                       (setq cns (cddr cns)))
                   (setcdr (cdr cns) (list tag child))
                   (setq in-progress nil)))
                ((eq cmp 'eq)
                 (if overwrite
                     (progn
                       (if (and (ptree-category-p child)
                                (ptree-category-p (cadr cns)))
                           (setq child (cadr cns))
                         (setcdr cns (cons child (cddr cns))))
                       (setq in-progress nil))
                   (signal 'ptree-node-already-existing (cons tag node))))
                (t (if prev-cns
                       (setcdr (cdr prev-cns) (cons tag (cons child cns)))
                     (setcdr node (cons tag (cons child (cdr node)))))
                   (setq in-progress nil)))))))
  child)

(defun ptree--delete-child-node (node tag)
  "Delete child node of NODE with TAG.
If NODE is a property, 'ptree-not-a-category error is signaled.
If such child node does not exist, 'ptree-node-not-existing error is raised."
  (if (ptree-property-p node)
      (signal 'ptree-not-a-category node)
    (if (not (cdr node))
        (signal 'ptree-node-not-existing (cons tag node))
      (let* ((cns (cdr node))
             (prev-cns nil)
             (in-progress t))
        (while in-progress
          (let ((cmp (ptree--compare-tags tag (car cns))))
            (if (eq cmp 'eq)
                (let ((actual-cns (if prev-cns (cdr prev-cns) node)))
                    (setcdr actual-cns (cdddr actual-cns))
                    (setq in-progress nil))
                (if (or (eq cmp 'lt) (not (cddr cns)))
                    (signal 'ptree-node-not-existing (cons tag node))
                  (setq prev-cns cns)
                  (setq cns (cddr cns))))))))))

(defun ptree--write-path (node path)
  "Create a PATH up to a descentant node starting from NODE.
PATH is the list of tags that shall be followed to reach the descendant node.
If only one tag has to be specified, it is possible to set PATH to the value
of the tag instead of passing PATH as a list with a single tag.
If PATH is nil, the descendant of NODE is NODE itself.
If a node in the path does not exist, it is created.
If a node in the path is a property, it is turned into a catagory.
The function return the descendant node."
  (while path
    (setq node (ptree--add-child-node node (car path) (list nil) t))
    (setq path (cdr path)))
  node)

(defun ptree--iter-step-down (iterator)
  "Move ITERATOR down the property tree by one step.
If it is not possible to perform the step because the node is the iterator
inital node, the function returns 'nil.
Otherwise the function returns 't."
  (let ((node (cadr iterator)))
    (if (or (car node) (not (cdr node)))
        nil
      (setcdr iterator (cons (caddr node)
                             (cons (cons (cons (car iterator)
                                               (cdr iterator)) (caddr iterator))
                                   (list (cdddr node)))))
      (setcar iterator (cadr node))
      t)))

(defun ptree--iter-step-up (iterator)
  "Move ITERATOR up the property tree by one step.
If it is not possible to perform the step because the node is a property or
because it has no child nodes, the function returns 'nil.
Otherwise the function returns 't."
  (let ((parent-iter (caaddr iterator)))
    (if (not parent-iter)
        nil
      (setcar iterator (car parent-iter))
      (setcdr iterator (cdr parent-iter))
      t)))

(defun ptree--iter-step-next (iterator)
  "Move ITERATOR to the next sibling node of the property tree by one step.
If it is not possible to perform the step because the node is a property or
because it has no child nodes, the function returns 'nil.
Otherwise the function returns 't."
  (let ((next-nodes (cadddr iterator)))
    (if (not next-nodes)
        nil
      (setcdr iterator (cons (cadr next-nodes)
                             (cons (caddr iterator)
                                   (cons (cddr next-nodes)
                                         (cons (cadr iterator)
                                               (cons (car iterator)
                                                     (cddddr iterator)))))))
      (setcar iterator (car next-nodes))
      t)))

(defun ptree--iter-step-previous (iterator)
  "Move ITERATOR to the previous sibling node of the property tree by one step.
If it is not possible to perform the step because the node is a property or
because it has no child nodes, the function returns 'nil.
Otherwise the function returns 't."
  (let ((previous-nodes (cddddr iterator)))
    (if (not previous-nodes)
        nil
      (setcdr iterator (cons (car previous-nodes)
                             (cons (caddr iterator)
                                   (cons (cons (car iterator)
                                               (cons (cadr iterator)
                                                     (cadddr iterator)))
                                         (cddr previous-nodes)))))
      (setcar iterator (cadr previous-nodes))
      t)))

(defun ptree--node-to-string (tag node level indent)
  "Convert NODE with TAG at LEVEL to string."
  (let ((tag-str (format "%S" tag))
        (prefix (concat (make-string (* indent level) ?\s))))
       (if (ptree-property-p node)
           (format "%s%s: %S\n" prefix tag-str (ptree-property-value node))
    (format "%s%s\n" prefix tag-str))))

;; Package provision

 (provide 'ptree)

;;; ptree.el ends here
