;;; treeview.el --- A generic tree navigation library -*- lexical-binding: t -*-

;; Copyright (C) 2018-2022 Tilman Rassy

;; Author: Tilman Rassy <tilman.rassy@googlemail.com>
;; URL: https://github.com/tilmanrassy/emacs-treeview
;; Package-Version: 20220928.43
;; Package-Commit: d9c10feddf3b959e7b33ce83103e1f0a61162723
;; Version: 1.1.1
;; Package-Requires: ((emacs "24.4"))
;; Keywords: lisp, tools, internal, convenience

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

;; Abstract framework for tree navigation.  Based on this framework, specific libraries for
;; particular hierarchical data can be implemented, for example, file systems.
;; 
;; A typical tree would look like the following:
;;
;;   [+] Node 1
;;   [-] Node 2
;;    |    [+] Node 21
;;    |    [+] Node 22
;;    |    [-] Node 23
;;    |     |    [+] Node 231
;;    |     |      Leaf 231
;;    |     |      Leaf 232
;;    |     |      Leaf 233
;;    |    [+] Node 24
;;   [+] Node 3
;;   [+] Node 4
;;
;; Each node has a "label".  Non-leaf nodes also have a "control".  The label is the text by which
;; the node is represented.  The control is a clickable piece of text in front of the label which
;; allows the user to fold or unfold the node.  Nodes without children usually don't have a control.
;; Nodes can also have an icon, but this is optional.  Icons are implemented as images or symbols in
;; an icon font.  Control, icon, and label are always displayed in this order, and are always
;; displayed in one line.  Thus, multi-line nodes are not supported by this library.
;;
;; Nodes are represented by lists of the form:
;;
;;   (NAME PROPS PARENT CHILDREN)
;;
;; where the elements have the following meaning:
;;
;;   NAME      The name of the node.  A string.
;;
;;   PROPS     The properties of the node.  A plist.  See below for details.
;;
;;   PARENT    The parent of the node.  Another node-representing list.
;;
;;   CHILDREN  The children of the node.  List of node-representing lists.
;;
;; Node properties are implemented as plists with Lisp symbols as keys.  The following
;; properties exist:
;;
;;   node-line-overlay
;;          The overlay containing the node line
;;
;;   indent-overlay
;;          The overlay containing the node indentation
;;
;;   label-overlay
;;          The overlay containing the node label
;;
;;   control-overlay
;;          The overlay containing the node control
;;
;;   icon-overlay
;;          The overlay containing the node icon
;;
;;   start  A marker at the position where the node begins
;;
;;   end    A marker at the position where the node ends
;;
;;   state  The state of the node.  See below for details
;;
;;   selected
;;          Whether the node is selected (non-nil if selected, nil if not)
;;
;; Node states: Each node is in exactly one of three states, which are represented by the
;; following Lisp symbols:
;;
;;   folded-unread   The node is folded and has not been unfolded before
;;
;;   folded-read     The node is folded, but has been unfolded before
;;
;;   expanded        The node is expanded
;;
;; Initially, a node is in the state 'folded-unread'.  If it gets expanded for the first time,
;; the state changes to 'expanded'.  If it gets folded again, the state changes to 'folded-read'.
;; From then, the state toggles between 'expanded' and 'folded-read' each time the node is
;; expanded or folded.
;;
;; The framework is used by implementing several functions which are defined as function variables,
;; thus, variables whose values are function symbols.  Here is a list of that variables:
;;
;;   treeview-get-root-node-function
;;   treeview-node-leaf-p-function
;;   treeview-update-node-children-function
;;   treeview-after-node-expanded-function
;;   treeview-after-node-folded-function
;;   treeview-get-indent-function
;;   treeview-get-control-function
;;   treeview-get-control-margin-left-function
;;   treeview-get-control-margin-right-function
;;   treeview-get-icon-function
;;   treeview-get-icon-margin-left-function
;;   treeview-get-icon-margin-right-function
;;   treeview-get-label-function
;;   treeview-get-label-margin-left-function
;;   treeview-get-control-keymap-function
;;   treeview-get-indent-face-function
;;   treeview-get-control-face-function
;;   treeview-get-control-mouse-face-function
;;   treeview-get-selected-node-face-function
;;   treeview-get-highlighted-node-face-function
;;   treeview-get-label-keymap-function
;;   treeview-get-label-face-function
;;   treeview-get-label-mouse-face-function
;;   treeview-get-icon-keymap-function
;;   treeview-get-icon-face-function
;;   treeview-get-icon-mouse-face-function
;;   treeview-suggest-point-pos-in-control-function
;;
;; A description of each variable can be found in the repsetive documentation strings.  All
;; variables are buffer-local.  Libraries using this framework should create a new buffer and
;; set the variables to particular functions in that buffer.  Then, the root node should be
;; created and rendered in the buffer by a call to treeview-display-node.
;;
;; See library "dir-treeview" for an example where this framework is used.
;;
;; If you upgrade from v1.0.0: Note that since v1.1.0 another buffer-local function variable
;; treeview-get-root-node-function exists which didn't exist in v1.0.0. It must be set to a
;; function which returns the root node of the tree.

;;; Code:

(define-error 'treeview-error "Treeview error" 'error)
(define-error 'treeview-invalid-node-state-error "Invalid node state" 'treeview-error)

(defun treeview-new-node ()
  "Create and return a new node.
The name, parent and children of the new node are nil.  The properties have only
the entry `state' with the value `folder-unread'."
  (list nil                           ;; name
        (list 'state 'folded-unread)  ;; properties
        nil                           ;; parent
        nil))                         ;; children

(defun treeview-get-node-name (node)
  "Return the name of NODE."
  (car node))

(defun treeview-set-node-name (node name)
  "Set NODE's name to NAME."
  (setcar node name))

(defun treeview-get-node-props (node)
  "Return the properties of NODE."
  (nth 1 node))

(defun treeview-set-node-props (node props)
  "Set the properties of NODE to PROPS."
  (setcar (nthcdr 1 node) props))

(defun treeview-get-node-prop (node key)
  "Return the property KEY of NODE.
If the property is not set, returns nil."
  (plist-get (treeview-get-node-props node) key))

(defun treeview-set-node-prop (node key value)
  "Set the property KEY of NODE to VALUE."
  (let ( (props (treeview-get-node-props node)) )
    (treeview-set-node-props node (plist-put props key value))))

(defun treeview-get-node-state (node)
  "Return the state of NODE."
  (treeview-get-node-prop node 'state))

(defun treeview-set-node-state (node state)
  "Set the state of NODE to STATE."
  (unless (memq state '(folded-unread folded-read expanded))
    (error 'treeview-invalid-node-state-error state))
  (treeview-set-node-prop node 'state state))

(defun treeview-node-unread-p (node)
  "Return non-nil if NODE's children have not been read yet.
This is the case if, and only if, NODE's state is `folded-unread'."
  (eq (treeview-get-node-state node) 'folded-unread))

(defun treeview-node-folded-p (node)
  "Return non-nil if NODE is folded.
This is the case if and only if NODES's state is `folded-unread'
or `folded-read'."
  (memq (treeview-get-node-state node) '(folded-unread folded-read)))

(defun treeview-node-expanded-p (node)
  "Return non-nil if NODE is expanded, otherwise nil."
  (eq (treeview-get-node-state node) 'expanded))

(defun treeview-get-node-parent (node)
  "Return the parent of NODE."
  (nth 2 node))

(defun treeview-set-node-parent (node parent)
  "Set the parent of NODE to PARENT."
  (setcar (nthcdr 2 node) parent))

(defun treeview-get-node-children (node)
  "Return the children of NODE."
  (nth 3 node))

(defun treeview-set-node-children (node children)
  "Set the children of NODE to CHILDREN."
  (setcar (nthcdr 3 node) children))

(defvar treeview-get-root-node-function nil
  "Function that returns the root node of the tree.")

(make-variable-buffer-local 'treeview-get-root-node-function)

(defun treeview-get-root-node ()
  "Return the root node of the tree.
Calls `treeview-get-root-node-function', which must be implemented."
  (funcall treeview-get-root-node-function))

(defun treeview-get-parent-children (node)
  "Return the children of the parent of NODE.
If NODE has no parent, return nil."
  (let ( (parent (treeview-get-node-parent node)) )
    (if parent (treeview-get-node-children parent) )))

(defun treeview-get-next-sibling (node)
  "Return the next sibling of NODE.
If NODE does not have a next sibling, returns nil."
  (let ( (siblings (treeview-get-parent-children node)) )
    (when siblings
      (while (not (eq (car siblings) node)) (setq siblings (cdr siblings)))
      (setq siblings (cdr siblings))
      (when siblings (car siblings)))))

(defun treeview-last-child-p (node)
  "Return non-nil of NODE is the last child, otherwise nil."
  (let ( (parent (treeview-get-node-parent node)) )
    (or (not parent)
        (let* ( (parent-children (treeview-get-node-children parent))
                (last-parent-child (if parent-children (car (last parent-children)))) )
          (eq last-parent-child node)))))

(defun treeview-parent-is-last-child-p (node)
  "Return non-nil if the parent of NODE is the last child of its parent,
otherwise nil."
  (let ( (parent (treeview-get-node-parent node)) )
    (if parent (treeview-last-child-p parent) t)))

(defvar treeview-node-leaf-p-function
  (lambda (node)
    (or (treeview-node-unread-p node) (not (treeview-get-node-children node))))
  "Function that returns non-nil if NODE is a leaf of the tree.
The default implementation considers a node to be a leaf if, and only if, the
node has no children or is unread (i.e., its state is `folded-unred'.")

(make-variable-buffer-local 'treeview-node-leaf-p-function)

(defun treeview-node-leaf-p (node)
  "Return non-nil if NODE is a leaf of the tree; otherwise, return nil.
Calls the buffer local function `treeview-node-leaf-p-function' with one
argument, NODE."
  (funcall treeview-node-leaf-p-function node))

(defun treeview-node-not-hidden-p (node)
  "Return non-nil if NODE is not hidden, otherwise nil.
A node is not hidden if all its ancestors are expanded.  A node with no
ancestors (thus, the root node) is also not hidden."
  (let ( (parent (treeview-get-node-parent node)) )
    (or (not parent) (and (treeview-node-expanded-p parent) (treeview-node-not-hidden-p parent)))))

(defun treeview-node-expanded-and-not-hidden-p (node)
  "Return non-nil if NODE is expanded and not hidden, otherwise nil.
A node is not hidden if all its ancestors are expanded.  A node with no
ancestors (thus, the root node) is also not hidden."
  (and (treeview-node-expanded-p node) (treeview-node-not-hidden-p node)))

(defun treeview-put (&rest objects)
  "Insert OBJECTS at point.
Each element of OBJECTS may be a string, a character, an image, nil, or a list.
If nil, the element is ignored.  If a list, the function recursively calls
itself."
  (while objects
    (let ( (object (car objects)) )
      (when object
        (if (listp object)
            (if (eq (car object) 'image)
                ;; It's an image
                (let ( (start (point)) )
                  (insert " ")
                  (put-text-property start (point) 'display object))
              ;; It's a list of objects
              (apply #'treeview-put object))
          ;; It's a string or character
          (insert object) ))
      (setq objects (cdr objects)) )))

(defun treeview-return-nil (_node)
  "Return nil.
Default implementation of functions that provide optional data, e.g.,
`treeview-get-control-face-function'.  The argument _NODE is ignored."
  nil)

(defun treeview-do-nothing (_node)
  "Do nothing.
Default implementation of functions that may be used to perform additional
actions on certain occasions, e.g., `treeview-after-node-expanded-function'.
Always returns t."
  t)

(defun treeview-not-nil-or-empty-string-p (str)
  "Return non-nil if STR is neither nil nor the empty string."
  (and str (not (string-equal str ""))))

(defvar treeview-update-node-children-function nil
  "Function that updates the children of a node.
Called with one argument, the node.  For example, if the nodes represent
directories, this function could re-read the directory to update the children.
The function should not redisplay the node, this is done automatically.")

(make-variable-buffer-local 'treeview-update-node-children-function)

(defvar treeview-after-node-expanded-function 'treeview-do-nothing
  "Function to perform additional actions after a node has been expanded.
Called with one argument, the node.")

(make-variable-buffer-local 'treeview-after-node-expanded-function)

(defvar treeview-after-node-folded-function 'treeview-do-nothing
  "Function to perform additional actions after a node has been expanded.
Called with one argument, the node.")

(make-variable-buffer-local 'treeview-after-node-folded-function)

(defvar treeview-get-indent-function nil
  "Function to create the indentation before a node.
Called with one argument, the node.  Should return a list of strings.  These are
concatenated to the indentation.")

(make-variable-buffer-local 'treeview-get-indent-function)

(defvar treeview-get-control-function 'treeview-return-nil
  "Function to create and return the control of a node.
Called with one argument, the node.  Should return a string or nil.  In the
latter case the node  does not get a control.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-control-function)

(defvar treeview-get-control-margin-left-function 'treeview-return-nil
  "Function to create the left margin of a node control.
Called with one argument, the node.  The return value is inserted with
`treeview-put'.  Thus, the return value  must be a string, a character, nil, or
a list.  If nil, the left margin is suppressed.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-control-margin-left-function)

(defvar treeview-get-control-margin-right-function 'treeview-return-nil
  "Function to create the right margin of a node control.
Called with one argument, the node.  The return value is inserted with
`treeview-put'.  Thus, the return value  must be a string, a character, nil, or
a list.  If nil, the right margin is suppressed.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-control-margin-right-function)

(defvar treeview-get-icon-function 'treeview-return-nil
  "Function to create and return the icon of a node.
Called with one argument, the node.  Should return a string or nil.  In the
latter case the node does not get an icon.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-icon-function)

(defvar treeview-get-icon-margin-left-function 'treeview-return-nil
  "Function to create the left margin of a node icon.
Called with one argument, the node.  The return value is inserted with
`treeview-put'.  Thus, the return value  must be a string, a character, nil, or
a list.  If nil, the left margin is suppressed.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-icon-margin-left-function)

(defvar treeview-get-icon-margin-right-function 'treeview-return-nil
  "Function to create the right margin of a node icon.
Called with one argument, the node.  The return value is inserted with
`treeview-put'.  Thus, the return value  must be a string, a character, nil, or
a list.  If nil, the right margin is suppressed.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-icon-margin-right-function)

(defvar treeview-get-label-function 'treeview-return-nil
  "Function to create and retrun the label of a node.
Called with one argument, the node.  Should return a string or nil.  In the
latter case the node does not get a label.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-label-function)

(defvar treeview-get-label-margin-left-function 'treeview-return-nil
  "Function to create the left margin of a node label.
Called with one argument, the node.  The return value is inserted with
`treeview-put'.  Thus, the return value  must be a string, a character, nil, or
a list.  If nil, the left margin is suppressed.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-label-margin-left-function)

(defvar treeview-get-control-keymap-function 'treeview-return-nil
  "Function to get the keymap of the control of a node.
Called with one argument, the node.  The return value is passed as the KEYMAP
argument to `treeview-make-node-component-overlay'.  Thus, the return value must
be a keymap or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-control-keymap-function)

(defvar treeview-get-indent-face-function 'treeview-return-nil
  "Function to get the face of the indentation of a node.
Called with one argument, the node.  The return value is passed as the FACE
argument to `treeview-make-node-component-overlay'.  Thus, the return value must
be a face or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-indent-face-function)

(defvar treeview-get-control-face-function 'treeview-return-nil
  "Function to get the face of the control of a node.
Called with one argument, the node.  The return value is passed as the FACE
argument to `treeview-make-node-component-overlay'.  Thus, the return value must
be a face or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-control-face-function)

(defvar treeview-get-control-mouse-face-function 'treeview-return-nil
  "Function to get the mouse face of the control of a node.
Called with one argument, the node.  The return value is passed as the
MOUSE-FACE argument to `treeview-make-node-component-overlay'.  Thus, the return
value must be a face or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-control-mouse-face-function)

(defvar treeview-get-selected-node-face-function 'treeview-return-nil
  "Function to get the face of selected nodes.
Called with one argument, the node.  The return value must be a face or nil.
If a face, it is used to highlight selected nodes.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-selected-node-face-function)

(defvar treeview-highlighted-node nil
  "The highlighted node, or nil if currently no node is highlighted.")

(make-variable-buffer-local 'treeview-highlighted-node)

(defvar treeview-get-highlighted-node-face-function 'treeview-return-nil
  "Function to get the face to highlighted a node.
Called with one argument, the node.  The return value must be a face or nil.
If a face, it is used to highlight the node.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-highlighted-node-face-function)

(defvar treeview-get-label-keymap-function 'treeview-return-nil
  "Function to get the keymap of the label of a node.
Called with one argument, the node.  The return value is passed as the KEYMAP
argument to `treeview-make-node-component-overlay'.  Thus, the return value must
be a keymap or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-label-keymap-function)

(defvar treeview-get-label-face-function 'treeview-return-nil
  "Function to get the mouse face of the label of a node.
Called with one argument, the node.  The return value is passed as the
MOUSE-FACE argument to `treeview-make-node-component-overlay'.  Thus, the
return value must be a face or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-label-face-function)

(defvar treeview-get-label-mouse-face-function 'treeview-return-nil
  "Function to get the mouse face of the label of a node.
Called with one argument, the node.  The return value is passed as the
MOUSE-FACE argument to `treeview-make-node-component-overlay'.  Thus, the
return value must be a face or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-label-mouse-face-function)

(defvar treeview-get-icon-keymap-function 'treeview-return-nil
  "Function to get the keymap of the icon of a node.
Called with one argument, the node.  The return value is passed as the KEYMAP
argument to `treeview-make-node-component-overlay'.  Thus, the return value must
be a keymap or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-icon-keymap-function)

(defvar treeview-get-icon-face-function 'treeview-return-nil
  "Function to get the mouse face of the icon of a node.
Called with one argument, the node.  The return value is passed as the
MOUSE-FACE argument to `treeview-make-node-component-overlay'.  Thus, the return
value must be a face or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-icon-face-function)

(defvar treeview-get-icon-mouse-face-function 'treeview-return-nil
  "Function to get the mouse face of the icon of a node.
Called with one argument, the node.  The return value is passed as the
MOUSE-FACE argument to `treeview-make-node-component-overlay'.  Thus, the
return value must be a face or nil.

The default implementation is `treeview-return-nil'.")

(make-variable-buffer-local 'treeview-get-icon-mouse-face-function)

(defun treeview-apply-recursively (node callback)
  "Apply CALLBACK to NODE and all its descendants.
CALLBACK should be a function expecting a node as argument."
  (funcall callback node)
  (dolist (child (treeview-get-node-children node))
    (treeview-apply-recursively child callback)))

(defun treeview-for-each-node (callback)
  "Apply CALLBACK to each node in the tree.
CALLBACK should be a function expecting a node as argument."
  (treeview-apply-recursively (treeview-get-root-node) callback))

(defun treeview-filter-nodes (filter)
  "Return a list of all nodes accepted by FILTER.
FILTER must be function expecting a node as argument.  A node is said to be
accepted by FILTER if FILTER returns a non-nil value when applied to the
node."
  (let ( (nodes ()) )
    (treeview-for-each-node (lambda (node) (when (funcall filter node) (push node nodes))))
    nodes))

(defun treeview-get-node-at-pos (pos)
  "Return the node at the buffer position POS,
or nil if there is no node at that position."
  (let ( (overlays (overlays-at pos t))
         (node nil) )
    (while (and overlays (not node))
      (setq node (overlay-get (car overlays) 'treeview-node)
            overlays (cdr overlays)))
    node))

(defun treeview-get-node-at-point ()
  "Return the node at point, or nil if there is no node at point."
  (treeview-get-node-at-pos (point)))

(defun treeview-get-node-at-event (event)
  "Return the node at the position of EVENT.
If there is no node at that position, nil is returned.  The function assumes
that the event occurred in the current buffer, and that the current buffer is a
treeview buffer.  It should be called only if this is guaranteed."
  (treeview-get-node-at-pos (posn-point (event-start event))))

(defun treeview-first-line-p ()
  "Return non-nil if point is in the first line of the buffer, otherwise nil."
  (save-excursion
    (beginning-of-line)
    (bobp)))

(defun treeview-last-line-p ()
  "Return non-nil if point is in the last line of the buffer, otherwise nil."
  (save-excursion
    (end-of-line)
    (eobp)))

(defun treeview-find-node-in-current-line ()
  "Find and return the node in the current line.
If there is no node in the current line, return nil."
  (save-excursion
    (move-to-column 0)
    (treeview-get-node-at-pos (point))))

(defun treeview-find-next-node ()
  "Find and return the next node in the lines following the current line.
If no such node exists, return nil."
  (save-excursion
    (let ( (node nil) )
      (while (not (or (treeview-last-line-p) node))
        (forward-line)
        (setq node (treeview-get-node-at-point)))
      node)))

(defun treeview-find-previous-node ()
  "Find and return the previous node.
This is the closest node in the lines preceeding the current line.  If no such
node exists, return nil."
  (save-excursion
    (let ( (node nil) )
      (while (not (or (treeview-first-line-p) node))
        (forward-line -1)
        (setq node (treeview-get-node-at-point)))
      node)))

(defun treeview-inside-node-p (pos node)
  "Return non-nil if POS is a position inside NODE, otherwise nil."
  (and (<= (marker-position (treeview-get-node-prop node 'start)) pos)
       (<= pos (marker-position (treeview-get-node-prop node 'end)))))

(defun treeview-make-node-component-overlay (node content &optional keymap face mouse-face)
  "Create an overlay representing a specific component of a node.

This function is used to create the indentation, control, icon, and label
overlays of nodes.  NODE is the node to which the overlay belongs.  The
`treeview-node' property of the overlay is set to NODE.  CONTENT is a string.
It is inserted as the content of the overlay.  If non-nil, KEYMAP, FACE, and
MOUSE-FACE are the keymap, face, and mouse face of the overlay, respectively.

The overlay is inserted at the current point position.  Thus, the overlay
starts where the point was when the function was called.  The point is moved
to the position after the overlay end by this function.

The overlay gets the priority 300.

The function returns the new overlay."
  (let* ( (start (point))
          (overlay (progn (treeview-put content) (make-overlay start (point)))) )
    (overlay-put overlay 'treeview t)
    (overlay-put overlay 'treeview-node node)
    (overlay-put overlay 'priority 300)
    (if keymap (overlay-put overlay 'keymap keymap))
    (if face (overlay-put overlay 'face face))
    (if mouse-face (overlay-put overlay 'mouse-face mouse-face))
    overlay))

(defun treeview-make-node-line-overlay (node start end)
  "Create the overlay covering the line of NODE.

NODE is the node to which the overlay belongs.  The `treeview-node' property of
the overlay is set to NODE.  START and END are the start and end positions of
the overlay (integers or markers).  They should point to the beginning and end
of the line containing NODE, respectively.

The overlay gets the priority 200.

The function returns the new overlay."
  (let ( (overlay (make-overlay start end)) )
    (overlay-put overlay 'treeview t)
    (overlay-put overlay 'treeview-node node)
    (overlay-put overlay 'priority 200)
    overlay))

(defun treeview-make-text-overlay (text &optional keymap face mouse-face)
  "Insert TEXT at point and create and return an overlay containing that text.
If non-nil, KEYMAP, FACE, and MOUSE-FACE become the keymap, face,
and mouse face of the overlay, respectively
\(see Info node `(elisp) Overlay Properties')."
  (let* ( (start (point))
          (overlay (progn (insert text) (make-overlay start (point)))) )
    (if keymap (overlay-put overlay 'keymap keymap))
    (if face (overlay-put overlay 'face face))
    (if mouse-face (overlay-put overlay 'mouse-face mouse-face))
    overlay))

(defun treeview-add-face (base-face face-to-add)
  "Add FACE-TO-ADD to BASE-FACE.
This is an auxiliary function to create face lists for overlays.
BASE-FACE should be a face or a list of faces.  FACE-TO-ADD should be a face.
If BASE-FACE is a single face, the return value is the list
\(FACE-TO-ADD BASE-FACE).  If BASE-FACE is a list of faces (FACE1 FACE2 ...),
the return value is the list (FACE-TO-ADD FACE1 FACE2 ...)."
  (if (listp base-face)
      (unless (memq face-to-add base-face) (setq base-face (cons face-to-add base-face)))
    (unless (eq base-face face-to-add) (setq base-face (list face-to-add base-face))))
  base-face)

(defun treeview-remove-face (base-face face-to-remove)
  "Remove FACE-TO-REMOVE from BASE-FACE.

This is an auxiliary function to modify face (or face lists) of overlays.
BASE-FACE should be a face or a list of faces.  FACE-TO-REMOVE should be a face.

If BASE-FACE is a list of faces, it is checked if FACE-TO-REMOVE is a member.
Check is done with `memq'.  If so, FACE-TO-REMOVE is removed from the list.
If the remaining list has only one element, the element is returned.  Otherwise
the remaining list (which my be empty) is returned.

If BASE-FACE is a single face, and is equal to FACE-TO-REMOVE, an empty list is
returned.  Equality is checked with `eq'.

If BASE-FACE is a list not containing FACE-TO-REMOVE, or a single face other
than FACE-TO-REMOVE, BASE-FACE is returned unchecnged."
    (if (listp base-face)
        (when (memq face-to-remove base-face)
          (setq base-face (delq face-to-remove base-face))
          (when (equal (length base-face) 1) (setq base-face (nth 0 base-face))))
      (when (eq base-face face-to-remove)
        (setq base-face ())))
    base-face)

(defun treeview-add-node-label-face (node face-to-add)
  "Add FACE-TO-ADD the the face of the label of NODE.
FACE-TO-ADD is added to the face(s) of the overlay of NODE by means of
`'treeview-add-face."
  (let* ( (label-overlay (treeview-get-node-prop node 'label-overlay))
          (label-face (overlay-get label-overlay 'face)) )
    (overlay-put label-overlay 'face (treeview-add-face label-face face-to-add))))

(defun treeview-remove-node-label-face (node face-to-remove)
  "Remove FACE-TO-REMOVE from the face of the label of NODE.
FACE-TO-REMOVE is removed from the face(s) of the overlay of NODE by means of
`'treeview-remove-face."
  (let* ( (label-overlay (treeview-get-node-prop node 'label-overlay))
          (label-face (overlay-get label-overlay 'face)) )
    (overlay-put label-overlay 'face (treeview-remove-face label-face face-to-remove))))

(defun treeview-set-node-start (node &optional pos)
  "Set the start marker of NODE to POS.
If POS is nil, do nothing."
  (if pos (treeview-set-node-prop node 'start (copy-marker pos))))

(defun treeview-set-node-end (node &optional pos type)
  "Set the end marker of NODE.
The end marker is set to POS and its insertion type  to TYPE (see
`marker-insertion-type').  POS must be an integer buffer position or a marker,
and defaults to the current end marker of NODE (this can be used to change the
latter's insertion type).  If POS is nil and its default is also nil, nothing
is done."
  (if (not pos) (setq pos (treeview-get-node-prop node 'end)))
  (if pos (treeview-set-node-prop node 'end (copy-marker pos type))))

(defun treeview-render-node (node &optional append-newline-p)
  "Display NODE, i.e., render it in the current buffer.
The node is placed at the current line.  All descendent nodes are rendered by
calling this function recursively.  If APPEND-NEWLINE-P is non-nil, a newline
is appended to the node.

This is an auxiliary function used in `treeview-display-node'."
  (let ( (start nil)
         ;; Indentation:
         (indent (funcall treeview-get-indent-function node))
         (indent-face (funcall treeview-get-indent-face-function node))
         (indent-overlay nil)
         ;; Control:
         (control-margin-left (funcall treeview-get-control-margin-left-function node))
         (control-content (funcall treeview-get-control-function node))
         (control-keymap (funcall treeview-get-control-keymap-function node))
         (control-face (funcall treeview-get-control-face-function node))
         (control-mouse-face (funcall treeview-get-control-mouse-face-function node))
         (control-margin-right (funcall treeview-get-control-margin-right-function node))
         (control-overlay nil)
         ;; Icon:
         (icon-margin-left (funcall treeview-get-icon-margin-left-function node))
         (icon-content (funcall treeview-get-icon-function node))
         (icon-keymap (funcall treeview-get-icon-keymap-function node))
         (icon-face (funcall treeview-get-icon-face-function node))
         (icon-mouse-face (funcall treeview-get-icon-mouse-face-function node))
         (icon-margin-right (funcall treeview-get-icon-margin-right-function node))
         (icon-overlay nil)
         ;; Label:
         (label-margin-left (funcall treeview-get-label-margin-left-function node))
         (label-content (funcall treeview-get-label-function node))
         (label-keymap (funcall treeview-get-label-keymap-function node))
         (label-face (funcall treeview-get-label-face-function node))
         (label-mouse-face (funcall treeview-get-label-mouse-face-function node))
         (label-overlay nil)
         ;; Node line:
         (node-line-overlay nil) )
    (when (treeview-node-selected-p node)
      (setq label-face (treeview-add-face label-face (funcall treeview-get-selected-node-face-function node))))
    (beginning-of-line)
    (setq start (point))
    (treeview-set-node-start node start)
    (treeview-set-node-end node start t)
    ;; Indentation:
    (when indent
      (setq indent-overlay
            (treeview-make-node-component-overlay node indent nil indent-face)))
    ;; Control:
    (treeview-put control-margin-left)
    (when control-content
      (setq control-overlay
            (treeview-make-node-component-overlay node control-content control-keymap control-face control-mouse-face)))
    (treeview-put control-margin-right)
    ;; Icon:
    (treeview-put icon-margin-left)
    (when icon-content
      (setq icon-overlay
            (treeview-make-node-component-overlay node icon-content icon-keymap icon-face icon-mouse-face)))
    (treeview-put icon-margin-right)
    ;; Label:
    (treeview-put label-margin-left)
    (setq label-overlay
          (treeview-make-node-component-overlay node label-content label-keymap label-face label-mouse-face))
    ;; Node line:
    (setq node-line-overlay (treeview-make-node-line-overlay node start (point)))
    (unless (treeview-node-folded-p node)
      (let ( (children (treeview-get-node-children node)) )
        (if children (newline))
        (while children
          (treeview-render-node (car children) (setq children (cdr children)))) ))
    (treeview-set-node-end node nil nil)
    (if append-newline-p (newline))
    (treeview-set-node-prop node 'indent-overlay indent-overlay)
    (treeview-set-node-prop node 'control-overlay control-overlay)
    (treeview-set-node-prop node 'icon-overlay icon-overlay)
    (treeview-set-node-prop node 'label-overlay label-overlay)
    (treeview-set-node-prop node 'node-line-overlay node-line-overlay) ) )

(defun treeview-set-node-end-after-display (node)
  "Set the insertion type of the end marker of NODE and its descendants to t.
This is an auxiliary function used in `treeview-display-node'."
  (treeview-set-node-end node nil t)
  (unless (treeview-node-folded-p node)
    (let ( (children (treeview-get-node-children node)) )
      (while children
        (treeview-set-node-end-after-display (car children))
        (setq children (cdr children)) ))))

(defun treeview-display-node (node &optional append-newline-p)
  "Display NODE, i.e., render it in the current buffer.

The node is placed at the current line.  All descendent nodes are rendered as
well unless they are folded.  If APPEND-NEWLINE-P is non-nil, a newline is
appended to the node.

The main implementation is outsourced and split into two other functions:
`treeview-render-node' and `treeview-set-node-end-after-display'.
The first one does the rendering, the latter one fixes the
`marker-insertion-type's of the end markers of the rendered nodes."
  (let ( (buffer-read-only nil) )
    (treeview-render-node node append-newline-p)
    (treeview-set-node-end-after-display node)))

(defun treeview-insert-node-after (node anchor)
  "Insert NODE after ANCHOR.
ANCHOR must be a cons cell of the list of children of a node.  NODE is inserted
after this cons cell.  NODE is also displayed if the parent is not hidden."
  (let* ( (anchor-node (car anchor))
          (parent (treeview-get-node-parent anchor-node))
          (new-cons (cons node nil)) )
    (setcdr new-cons (cdr anchor))
    (setcdr anchor new-cons)
    (treeview-set-node-parent node parent)
    (when (treeview-node-expanded-and-not-hidden-p parent)
      (let ( (buffer-read-only nil) )
        (goto-char (treeview-get-node-prop anchor-node 'end))
        (end-of-line)
        ;; Set insertion type of end marker of anchor-node to nil, to prevent marker from moving:
        (treeview-set-node-end anchor-node nil nil)
        (newline)
        ;; Reset insertion type of end marker of anchor-node:
        (treeview-set-node-end anchor-node nil t)
        (treeview-render-node node nil)
        (treeview-set-node-end-after-display node) )) ))

(defun treeview-add-child-at-front (parent node)
  "Insert NODE at the beginning of the children of PARENT.
Thus, NODE becomes the new first child of PARENT.  NODE is also displayed if
PARENT is not hidden."
  (let ( (children (treeview-get-node-children parent)) )
    (setq children (cons node children))
    (treeview-set-node-parent node parent)
    (treeview-set-node-children parent children)
    (when (treeview-node-expanded-and-not-hidden-p parent)
      (let ( (buffer-read-only nil) )
        (goto-char (treeview-get-node-prop parent 'start))
        (end-of-line)
        (newline)
        (treeview-render-node node nil)
        (treeview-set-node-end-after-display node) )) ))

(defun treeview-add-child (parent node compare-function)
  "Add NODE to the children of PARENT.
NODE is inserted at a position in accordance with the ordering of the children
of PARENT.  It is assumed that the children of PARENT are ordered according to
COMPARE-FUNCTION.  The latter should be a function accepting two arguments, and
return non-nil if the first argument is less that the second with respect to the
 ordering."
  (let ( (cursor (treeview-get-node-children parent)) anchor )
    (while (and cursor (funcall compare-function node (car cursor)))
      (setq anchor cursor
            cursor (cdr cursor)))
    (if anchor (treeview-insert-node-after node anchor) (treeview-add-child-at-front parent node))))

(defun treeview-recursively-remove-overlays (node)
  "Remove all overlays of NODE and its descendents."
  (let ( (overlay-prop-keys '(indent-overlay control-overlay icon-overlay label-overlay node-line-overlay)) )
    (while overlay-prop-keys
      (let* ( (overlay-prop-key (car overlay-prop-keys))
              (overlay (treeview-get-node-prop node overlay-prop-key)) )
        (treeview-set-node-prop node overlay-prop-key nil)
        (if overlay (delete-overlay overlay))
        (setq overlay-prop-keys (cdr overlay-prop-keys)) )))
  (let ( (children (treeview-get-node-children node)) )
    (while children
      (treeview-recursively-remove-overlays (car children))
      (setq children (cdr children)) )) )

(defun treeview-undisplay-node (node &optional leave-no-gap)
  "Remove NODE and all its descendents from the display in the buffer.
If LEAVE-NO-GAP is non-nil, the node is removed without leaving a gap between
the previuos and following nodes.  Otherwise, an empty line remains.

The `start' and `end' properties of NODE are set to nil.  Except this, the
internal representation of the tree is not altered.  Neither NODE or its
descendents are removed from the children of their respective parents.

The main purpose of this function is to implement the functions
`treeview-redisplay-node' and `treeview-remove-node'."
  (let* ( (start (treeview-get-node-prop node 'start))
          (end (treeview-get-node-prop node 'end))
          (buffer-read-only nil) )
    (treeview-recursively-remove-overlays node)
    (when leave-no-gap
      ;; Move end position to end of previous line (if any) to remove node completely
      (save-excursion
        (goto-char start)
        (when (equal (forward-line -1) 0)
          (end-of-line)
          (setq start (point)))))
    (delete-region start end)
    (treeview-set-node-prop node 'start nil)
    (treeview-set-node-prop node 'end nil)))

(defun treeview-remove-child (node child)
  "Remove CHILD from the children of NODE."
  (treeview-set-node-children node (delq child (treeview-get-node-children node))))

(defun treeview-remove-node (node)
  "Remove NODE from the tree.
NODE is also erased from the display if its parent is not hidden.  It is also
erased if it has no parent, thus, if it is the root node."
  (let ( (parent (treeview-get-node-parent node) ) )
    (when parent (treeview-remove-child parent node))
    (when (treeview-node-not-hidden-p node) (treeview-undisplay-node node t))))

(defun treeview-redisplay-node (node)
  "Redisplay NODE.

NODE is erased by `treeview-undisplay-node' and displayed again by
`treeview-display-node'.  This function can be used to update the display of a
node after it has changed."
  (let ( (start-marker (treeview-get-node-prop node 'start)) )
    (treeview-undisplay-node node)
    (goto-char start-marker)
    (treeview-display-node node)))

(defun treeview-expand-node (node)
  "Expands NODE."
  (treeview-set-node-state node 'expanded)
  (funcall treeview-update-node-children-function node)
  (funcall treeview-after-node-expanded-function node))

(defun treeview-fold-node (node)
  "Folds NODE."
  (treeview-set-node-state node 'folded-read)
  (funcall treeview-update-node-children-function node)
  (funcall treeview-after-node-folded-function node))

(defun treeview-update-node (node)
  "Update NODE.

If NODE is not folded, the following is done: First, the function calls
`treeview-update-node-children-function' for NODE.  Then, the function
calls itself for all children of NODE.

If NODE is folded, does nothing."
  (unless (treeview-node-folded-p node)
    (funcall treeview-update-node-children-function node)
    (let ( (children (treeview-get-node-children node)) )
      (while children
        (treeview-update-node (car children))
        (setq children (cdr children)) )) ))

(defun treeview-toggle-node-state (node)
  "Unfolds NODE if it is folded, folds it if it is unfolded."
  (if (treeview-node-folded-p node) (treeview-expand-node node) (treeview-fold-node node))
  (treeview-redisplay-node node))

(defun treeview-toggle-node-state-at-event (event)
  "Toggle the state of the node where EVENT occurred.

EVENT may for example be a mouse click.  If there there is no node at the
position where EVENT occurred, does nothing.

See also `treeview-toggle-node-state'."
  (interactive "@e")
  (let ( (node (treeview-get-node-at-event event)) )
    (when node
      (treeview-toggle-node-state node)
      (mouse-set-point event))))

(defun treeview-toggle-node-state-at-point ()
  "Toggle the state of the node at point.
If there is no node at point, does nothing.

See also `treeview-toggle-node-state'."
  (interactive)
  (let ( (node (treeview-get-node-at-pos (point))) )
    (if node
        (let ( (old-pos (point)) )
          (treeview-toggle-node-state (treeview-get-node-at-pos (point)))
          (goto-char old-pos)))))

(defun treeview-get-overlay-center (overlay)
  "Return the position of the center of OVERLAY."
  (let* ( (start (overlay-start overlay))
          (end (overlay-end overlay))
          (offset (/ (- end start) 2)) )
    (+ start offset)))

(defun treeview-call-for-node-at-point (action-function)
  "Call ACTION-FUNCTION with the node at point as argument.
ACTION-FUNCTION is the symbol of the function.  If there is no node at point,
does nothing."
  (let ( (node (treeview-get-node-at-pos (point))) )
    (when node (funcall action-function node))))

(defun treeview-refresh-node (node)
  "Update and redisplay NODE.

First, NODE is updated by calling `treeview-update-node'.  Then, NODE is
redisplayed by calling `treeview-redisplay-node'."
  (let ( (pos (point)) )
    (treeview-update-node node)
    (treeview-redisplay-node node)
    (goto-char (if (<= pos (point-max)) (if (>= pos (point-min)) pos (point-min)) (point-max))) ))

(defun treeview-refresh-tree ()
  "Update and redisplay the entire tree."
  (interactive)
  (treeview-refresh-node (treeview-get-root-node)))

(defun treeview-refresh-node-at-point ()
  "Update and redisplay the node at point.
Calls `treeview-refresh-node' with the node at point.
If there is no node at point, does nothing."
  (interactive)
  (treeview-call-for-node-at-point 'treeview-refresh-node))

(defun treeview-refresh-subtree-at-point ()
  "Update and redisplay the subtree point is in.
If the node at point is expanded, calls `treeview-refresh-node' for the
node at point.  If the node at point is not expanded and its parent is not
nil, calls `treeview-refresh-node' for the parent.  If the node at point
is not expanded and its parent is nil, calls `treeview-refresh-node' for
the node at point.  If there is no node at point, does nothing."
  (interactive)
  (let ( (node (treeview-get-node-at-pos (point))) )
    (when node
      (unless (treeview-node-expanded-p node)
        (let ( (parent (treeview-get-node-parent node)) )
          (when parent (setq node parent))))
      (treeview-refresh-node node))))

(defvar treeview-suggest-point-pos-in-control-function 'treeview-get-overlay-center
  "Function to suggest an appropriate position for the point in a node control.
Called with one argument, the control overlay.  Auxiliary for implementing
functions with move the point to the control of a node.")

(make-variable-buffer-local 'treeview-suggest-point-pos-in-control-function)

(defun treeview-place-point-in-node (node)
  "Move the point to an appropriate position in NODE.

If NODE has a control, point is placed at the position obtained by calling
`treeview-suggest-point-pos-in-control-function' with the control overlay as
argument.  Otherwise, point is placed at the beginning of the label."
  (goto-char
   (or
    ;; Control:
    (let ( (control-overlay (treeview-get-node-prop node 'control-overlay)) )
      (if control-overlay
          (funcall treeview-suggest-point-pos-in-control-function control-overlay)))
    ;; Label:
    (overlay-start (treeview-get-node-prop node 'label-overlay)))))

(defun treeview-next-line ()
  "Move point one line down,
and, if there is a node in that line, move point to the node."
  (interactive)
  (forward-line)
  (let ( (node (treeview-get-node-at-point)) )
    (if node (treeview-place-point-in-node node))))

(defun treeview-previous-line ()
  "Move point one line up,
and, if there is a node in that line, move point to the node."
  (interactive)
  (forward-line -1)
  (let ( (node (treeview-get-node-at-point)) )
    (if node (treeview-place-point-in-node node))))

(defun treeview-goto-parent ()
  "Move the point to the parent of node at point.
If there is no node at point, or if the node has no parent, does nothing."
  (interactive)
  (let ( (node (treeview-find-node-in-current-line)) )
    (when node
      (let ( (parent (treeview-get-node-parent node)) )
        (when parent (treeview-place-point-in-node parent))))))

(defun treeview-goto-first-sibling ()
  "Move the point to the first sibling of the node at point.
If there is no node at point, does nothing."
  (interactive)
  (let ( (node (treeview-find-node-in-current-line)) )
    (when node
      (let ( (siblings (treeview-get-parent-children node)) )
        (treeview-place-point-in-node (if siblings (car siblings) node)) ))) )

(defun treeview-goto-last-sibling ()
  "Move the point to the first sibling of the node at point.
If there is no node at point, does nothing."
  (interactive)
  (let ( (node (treeview-find-node-in-current-line)) )
    (when node
      (let ( (siblings (treeview-get-parent-children node)) )
        (treeview-place-point-in-node (if siblings (car (last siblings)) node)) ))) )

(defun treeview-goto-parents-next-sibling ()
  "Move the point to the next sibling of the parent of the node at point.
If there is no node at point, or if the node has no parent, or if the parent
has no next sibling, does nothing."
  (interactive)
  (let ( (node (treeview-find-node-in-current-line)) )
    (when node
      (let ( (parent (treeview-get-node-parent node)) )
        (when parent
          (let ( (sibling (treeview-get-next-sibling parent)) )
            (when sibling (treeview-place-point-in-node sibling))))))))

(defun treeview-node-selected-p (node)
  "Return non-nil if NODE is selected, otherwise nil.
A node is selected if its property `selected' is non-nil."
  (treeview-get-node-prop node 'selected))

(defun treeview-select-node (node)
  "Select NODE.
The node's property `select' is set to t, and the node's label is highlighted
with the face returned by `treeview-get-selected-node-face-function'.  If the
node is already selected, does nothing"
  (unless (treeview-node-selected-p node)
    (treeview-set-node-prop node 'selected t)
    (treeview-add-node-label-face node (funcall treeview-get-selected-node-face-function node))))

(defun treeview-unselect-node (node)
  "Unselect NODE.
The node's property `select' is set to nil, and the highlighting as a selected
node is removed.  If the node isn't selected, does nothing"
  (when (treeview-node-selected-p node)
    (treeview-set-node-prop node 'selected nil)
    (treeview-remove-node-label-face node (funcall treeview-get-selected-node-face-function node))))

(defun treeview-get-all-selected-nodes ()
  "Return all selected nodes as a list."
  (treeview-filter-nodes 'treeview-node-selected-p))

(defun treeview-selected-nodes-exist ()
  "Return non-nil if at least one node is selected, otherwise nil."
  (> (length (treeview-get-all-selected-nodes)) 0))

(defun treeview-unselect-all-nodes ()
  "Unselect all selected nodes."
  (interactive)
  (dolist (node (treeview-get-all-selected-nodes)) (treeview-unselect-node node)))

(defun treeview-unselect-all-nodes-after-keyboard-quit ()
  "Unselect all nodes if `this-command' is `keyboard-quit'.
If this function is added to `post-command-hook', the selections are revoked
when \\<global-map> \\[keyboard-quit] is pressed."
  (when (eq this-command 'keyboard-quit) (treeview-unselect-all-nodes)))

(defun treeview-toggle-select-node (node)
  "Select NODE if it is not selected, unselect it otherwise."
  (if (treeview-node-selected-p node) (treeview-unselect-node node) (treeview-select-node node)))

(defun treeview-toggle-select-node-at-point ()
  "Toggle selection of node at point.
If there is no node at point, does nothing."
  (interactive)
  (let ( (node (treeview-get-node-at-point)) )
    (when node (treeview-toggle-select-node node)) ))

(defun treeview-toggle-select-node-at-event (event)
  "Toggle selection of node where EVENT occurred.
EVENT must be a mouse event.  If there is no node at EVENT, does nothing."
  (interactive "@e")
  (let ( (node (treeview-get-node-at-event event)) )
    (when node (treeview-toggle-select-node node)) ))

(defun treeview-select-gap-above-node (node)
  "Select all nodes between the nearest selected node above NODE and NODE.
NODE itself is also selected.  The search for the nearest selected node extends
only to siblings of node.

For example, if you have nodes

  NODE_1 *
  NODE_2
  NODE_3 *
  NODE_4
  NODE_5
  NODE_6

which are all siblings of each other, and * denotes selection, and NODE is
NODE_6, then the result is the following:

  NODE_1 *
  NODE_2
  NODE_3 *
  NODE_4 *
  NODE_5 *
  NODE_6 *

If there is no selected sibling above nOE, does nothing."
  (let ( (parent (treeview-get-node-parent node)) )
    (when parent
      (let ( (children (treeview-get-node-children parent)) (nodes-to-select nil) (candidates nil) )
        (while (and children (not nodes-to-select))
          (let ( (child (car children)) )
            (if (eq child node)
                (progn (push child candidates)
                       (setq nodes-to-select candidates) )
              (if (treeview-node-selected-p child)
                  (setq candidates (list child))
                (when candidates (push child candidates)) ))
            (setq children (cdr children)) ))
        (when nodes-to-select (dolist (elem nodes-to-select) (treeview-select-node elem))) )) ))

(defun treeview-select-gap-above-node-at-point ()
  "Select all nodes from the node at point to the nearest selected node above.
The node at point is also selected.
See `treeview-select-gap-above-node' for more information."
  (interactive)
  (let ( (node (treeview-get-node-at-point)) )
    (when node (treeview-select-gap-above-node node))))

(defun treeview-select-gap-above-node-at-event (event)
  "Select all nodes from the node at EVENT to the nearest selected node above.
The node at EVENT is also selected.  EVENT should be a mouse event.
See `treeview-select-gap-above-node' for more information."
  (interactive "@e")
  (let ( (node (treeview-get-node-at-event event)) )
    (when node (treeview-select-gap-above-node node))))

(defun treeview-unhighlight-node ()
  "Unhighlight the highlightwd node.
If there is no highlightwd node, does nothing."
  (when treeview-highlighted-node
    (let ( (node treeview-highlighted-node) )
      (treeview-remove-node-label-face node (funcall treeview-get-highlighted-node-face-function node)))
    (setq treeview-highlighted-node nil)))

(defun treeview-highlight-node (node)
  "Highlight NODE."
  (treeview-unhighlight-node)
  (treeview-add-node-label-face node (funcall treeview-get-highlighted-node-face-function node))
  (setq treeview-highlighted-node node))

(defun treeview-make-keymap (key-table)
  "Create and return a keymap from KEY-TABLE.
The latter must be an alist whose car's are strings describing key sequences in
a format understood by `kbd', and whose cdr's are commands."
  (let ( (keymap (make-keymap)) )
    (while key-table
      (let* ( (key-def (car key-table))
              (key-seq (car key-def))
              (key-cmd (cdr key-def)) )
        (define-key keymap (kbd key-seq) key-cmd)
        (setq key-table (cdr key-table))))
    keymap))

(provide 'treeview)

;;; treeview.el ends here
