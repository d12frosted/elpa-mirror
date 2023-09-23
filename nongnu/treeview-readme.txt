emacs-treeview
==============

Abstract Emacs Lisp framework for tree navigation. Based on this framework, specific libraries for particular
hierarchical data can be implemented, for example, file systems.

This document describes v1.1.1 of emacs-treeview. Consider [this notes](#updating-from-v100) for upgrading from v1.0.0. 

A typical tree could look like the following:

<pre>
   [+] Node 1
   [-] Node 2
    |    [+] Node 21
    |    [+] Node 22
    |    [-] Node 23
    |     |    [+] Node 231
    |     |      Leaf 231
    |     |      Leaf 232
    |     |      Leaf 233
    |    [+] Node 24
   [+] Node 3
   [+] Node 4
</pre>

Each node has a "label".  Non-leaf nodes also have a "control".  The label is the text by which the node is represented.  The control is a clickable piece of text  in front of the label which allows the user to fold or unfold the node.  Nodes without children usually don't have a control.  Nodes can also have an icon, but this is optional.  Icons are implemented as symbols in an icon font. Control, icon, and label are always displayed in this order. It is assumed that each node occupies one line in the representation. Thus, multi-line nodes are not supported by this library.

Nodes are represented by lists of the form:

<pre>
  (NAME PROPS PARENT CHILDREN)
</pre>

where the elements have the following meaning:

  *  `NAME`     &nbsp;&ndash;&nbsp;  The name of the node.  A string.
  *  `PROPS`    &nbsp;&ndash;&nbsp;  The properties of the node.  A plist.  See below for details.
  *  `PARENT`   &nbsp;&ndash;&nbsp;  The parent of the node.  Another node-representing list.
  *  `CHILDREN` &nbsp;&ndash;&nbsp;  The children of the node.  List of node-representing lists.

Node properties are implemented as plists with Lisp symbols as keys.  The following
properties exist:

  *  `node-line-overlay` &nbsp;&ndash;&nbsp; The overlay containing the node line
  *  `indent-overlay`    &nbsp;&ndash;&nbsp; The overlay containing the node indentation
  *  `label-overlay`     &nbsp;&ndash;&nbsp; The overlay containing the node label
  *  `control-overlay`   &nbsp;&ndash;&nbsp; The overlay containing the node control
  *  `icon-overlay`      &nbsp;&ndash;&nbsp; The overlay containing the node icon
  *  `start`             &nbsp;&ndash;&nbsp; A marker at the position where the node begins
  *  `end`               &nbsp;&ndash;&nbsp; A marker at the position where the node ends
  *  `state`             &nbsp;&ndash;&nbsp; The state of the node.  See below for details
  *  `selected`          &nbsp;&ndash;&nbsp; Whether the node is selected (non-nil if selected, nil if not)

Node states: Each node is in exactly one of three states, which are represented by the
following Lisp symbols:

  *  `folded-unread`  &nbsp;&ndash;&nbsp;  The node is folded and has not been unfolded before
  *  `folded-read`    &nbsp;&ndash;&nbsp;  The node is folded, but has been unfolded before
  *  `expanded`       &nbsp;&ndash;&nbsp;  The node is expanded

Initially, a node is in the state 'folded-unread'.  If it gets expanded for the first time,
the state changes to 'expanded'.  If it gets folded again, the state changes to 'folded-read'.
From then, the state toggles between 'expanded' and 'folded-read' each time the node is
expanded or folded.

The framework declares a couple of "abstract" functions in the sense of function variables, i.e.,
variables whose values are function symbols. If the framework is applied for a particular purpose,
specific implementations for these functions must be provided.  Here is a list of that function
variables:
  
  *  treeview-get-root-node-function
  *  treeview-node-leaf-p-function
  *  treeview-update-node-children-function
  *  treeview-after-node-expanded-function
  *  treeview-after-node-folded-function
  *  treeview-get-indent-function
  *  treeview-get-control-function
  *  treeview-get-control-margin-left-function
  *  treeview-get-control-margin-right-function
  *  treeview-get-icon-function
  *  treeview-get-icon-margin-left-function
  *  treeview-get-icon-margin-right-function
  *  treeview-get-label-function
  *  treeview-get-label-margin-left-function
  *  treeview-get-control-keymap-function
  *  treeview-get-indent-face-function
  *  treeview-get-control-face-function
  *  treeview-get-control-mouse-face-function
  *  treeview-get-selected-node-face-function
  *  treeview-get-highlighted-node-face-function
  *  treeview-get-label-keymap-function
  *  treeview-get-label-face-function
  *  treeview-get-label-mouse-face-function
  *  treeview-get-icon-keymap-function
  *  treeview-get-icon-face-function
  *  treeview-get-icon-mouse-face-function
  *  treeview-suggest-point-pos-in-control-function

A description of each variable can be found in the respective documentation strings.  All
variables are buffer-local.  Libraries using this framework should create a new buffer and
set the variables to particular functions in that buffer. Then, the root node should be
created and rendered in the buffer by a call to treeview-display-node.


### Updating from v1.0.0

Note that since v1.1.0 another buffer-local function variable
`treeview-get-root-node-function` exists which didn't exist in v1.0.0. It must be set to a
function which returns the root node of the tree.
