;;; doom.el --- DOM implementation and manipulation library

;; Copyright (C) 2001, 2018  Alex Schroeder <alex@gnu.org>

;; Author: Alex Schroeder <alex@gnu.org>
;;	Henrik.Motakef <elisp@henrik-motakef.de>
;;      Katherine Whitlock <toroidal-code@gmail.com>
;;      Syohei YOSHIDA <syohex@gmail.com>
;; Maintainer: Alex Schroeder
;; Version: 1.4
;; Package-Version: 20180301.2308
;; Package-Commit: e59040aefc92dd9b3134eb623624307fb9e4327b
;; Keywords: xml, dom
;; Package-Requires: ((cl-lib "0.5"))
;; URL: http://www.github.com/kensanata/doom.el/

;; This file is not part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; If you are working with XML documents, the parsed data structure
;; returned by the XML parser (xml.el) may be enough for you: Lists of
;; lists, symbols, strings, plus a number of accessor functions.
;;
;; If you want a more elaborate data structure to work with your XML
;; document, you can create a document object model (DOM) from the XML
;; data structure using doom.el.
;;
;; You can create a DOM from XML using `doom-make-document-from-xml'
;; with the input from `libxml-parse-xml-region'. See function documentation
;; below for an example
;;
;; This library is called doom instead of dom because Emacs now comes
;; with its own library called dom which does something slightly
;; different.

;;; On Interfaces and Classes

;; The elisp DOM implementation uses the doom-node structure to store all
;; attributes.  The various interfaces consist of sets of functions to
;; manipulate these doom-nodes.  The functions of a certain interface
;; share the same prefix.

;;; Code:

(eval-when-compile
  (require 'cl-lib)
  (require 'cl))
(require 'xml)

;; FIXME: Use symbols instead of numbers?
(defconst doom-element-node 1)
(defconst doom-attribute-node 2)
(defconst doom-text-node 3)
;; (defconst doom-cdata-section-node 4)
;; (defconst doom-entity-reference-node 5)
;; (defconst doom-entity-node 6)
;; (defconst doom-processing-instruction-node 7)
;; (defconst doom-comment-node 8)
(defconst doom-document-node 9)
;; (defconst doom-document-type-node 10)
;; (defconst doom-document-fragment-node 11)
;; (defconst doom-notation-node 12)

;; Default names used for Text and Document nodes.

(defconst doom-text-node-name '\#text)
(defconst doom-document-node-name '\#document)

;;; Exception DOMException

;; DOM operations only raise exceptions in "exceptional" circumstances,
;; i.e., when an operation is impossible to perform (either for logical
;; reasons, because data is lost, or because the implementation has
;; become unstable). In general, DOM methods return specific error
;; values in ordinary processing situations, such as out-of-bound errors
;; when using NodeList.

;; Implementations should raise other exceptions under other
;; circumstances. For example, implementations should raise an
;; implementation-dependent exception if a null argument is passed.

;; Some languages and object systems do not support the concept of
;; exceptions. For such systems, error conditions may be indicated using
;; native error reporting mechanisms. For some bindings, for example,
;; methods may return error codes similar to those listed in the
;; corresponding method descriptions.

(let ((errors
       ;; Note that the numeric code is not used at the moment.
       '((doom-hierarchy-request-err 3
	  "Node doesn't belong here")
	 (doom-wrong-document-err 4
	  "Node is used in a different document than the one that created it")
	 (doom-not-found-err 8
	  "A reference to a node was made in a context where it does not exist"))))
  (dolist (err errors)
    (put (nth 0 err)
	 'error-conditions
	 (list 'error 'doom-exception (nth 0 err)))
    (put (nth 0 err)
	 'error-message
	 (nth 2 err))))

(defun doom-exception (exception &rest data)
  "Signal error EXCEPTION, possibly providing DATA.
The error signaled has the condition 'doom-exception in addition
to the catch-all 'error and EXCEPTION itself."
  ;; FIXME: Redefine this to do something else?
  (signal exception data))

;;; Document Interface

;; The Document interface represents the entire HTML or XML document.
;; Conceptually, it is the root of the document tree, and provides the
;; primary access to the document's data.

;; Since elements, text nodes, comments, processing instructions, etc.
;; cannot exist outside the context of a Document, the Document interface
;; also contains the factory methods needed to create these objects. The
;; Node objects created have a ownerDocument attribute which associates
;; them with the Document within whose context they were created.

;; It should also be noted that the Document interface has accessors
;; directly derived from the Node interface, only with the prefix
;; `doom-document` instead of `dom node`. There is also an added field
;; `element` which denotes the root element of the document.


(defun doom-document-create-attribute (doc name)
  "Create an attribute of the given NAME.
DOC is the owner-document. This can then be added
to an element using the doom-node-attributes accesssor"
  (when (stringp name)
    (setq name (intern name)))
  (make-doom-attr
   :name name
   :type doom-attribute-node
   :owner-document doc))


(defun doom-document-create-element (doc type)
  "Create an element of the given TYPE.
TYPE will be interned, if it is a string.
DOC is the owner-document. Returns an ELEMENT"

;; TODO: If there are known attributes with default
;; values, Attr nodes representing them should be automatically created
;; and attached to the element.
  (when (stringp type)
    (setq type (intern type)))
  (make-doom-element
   :name type
   :type doom-element-node
   :owner-document doc))

;; createTextNode

;; Creates a Text node given the specified string.

(defun doom-document-create-text-node (doc data)
  "Create a text element containing DATA.
DOC is the owner-document."
  (make-doom-text
   :name doom-text-node-name
   :value data
   :type doom-text-node
   :owner-document doc))

;; getElementsByTagName

;; Returns a NodeList of all the Elements with a given tag name in the
;; order in which they are encountered in a preorder traversal of the
;; Document tree.

(defun doom-document-get-elements-by-tag-name (doc tagname)
  "Return a list of all the elements with the given tagname.
The elements are returned in the order in which they are encountered in
a preorder traversal of the document tree.  The special value \"*\"
matches all tags."
  (doom-element-get-elements-by-tag-name-1
   (doom-document-element doc)
   tagname))

;;; Interface Node

;; The Node interface is the primary datatype for the entire Document
;; Object Model. It represents a single node in the document tree. While
;; all objects implementing the Node interface expose methods for dealing
;; with children, not all objects implementing the Node interface may have
;; children. For example, Text nodes may not have children, and adding
;; children to such nodes results in a DOOMException being raised.

;; The attributes name, value and attributes are included as a mechanism
;; to get at node information without casting down to the specific
;; derived interface. In cases where there is no obvious mapping of
;; these attributes for a specific type (e.g., value for an Element or
;; attributes for a Comment), this returns null. Note that the
;; specialized interfaces may contain additional and more convenient
;; mechanisms to get and set the relevant information.

;; readonly attribute DOOMString        nodeName;
;;          attribute DOOMString        nodeValue;
;; readonly attribute unsigned short   nodeType;
;; readonly attribute Node             parentNode;
;; readonly attribute NodeList         childNodes;
;; readonly attribute Node             firstChild;
;; readonly attribute Node             lastChild;
;; readonly attribute Node             previousSibling;
;; readonly attribute Node             nextSibling;
;; readonly attribute NamedNodeMap     attributes;
;; readonly attribute Document         ownerDocument;

(cl-defstruct doom-node
  (name nil :read-only t)
  value
  (type nil :read-only t)
  parent-node
  child-nodes
  attributes
  owner-document)

(cl-defstruct (doom-document (:include doom-node))
  element)

(cl-defstruct (doom-element (:include doom-node)))

(cl-defstruct (doom-attr (:include doom-node))
  owner-element
  specified)

(cl-defstruct (doom-character-data (:include doom-node)))

(cl-defstruct (doom-text (:include doom-character-data)))



;; All functions defined for nodes are defined for documents, elements
;; and attributes as well. Generator function.

;; The following functions implement the virtual attributes first-child,
;; last-child, previous-sibling and next-sibling.

(defun doom-node-first-child (node)
  (car (doom-node-child-nodes node)))
(defalias 'doom-document-first-child 'doom-node-first-child)
(defalias 'doom-element-first-child 'doom-node-first-child)
(defalias 'doom-attr-first-child    'doom-node-first-child)

(defun doom-node-last-child (node)
  (car (last (doom-node-child-nodes node))))
(defalias 'doom-document-last-child 'doom-node-last-child)
(defalias 'doom-element-last-child 'doom-node-last-child)
(defalias 'doom-attr-last-child    'doom-node-last-child)

(defun doom-node-previous-sibling (node)
  (let ((parent (doom-node-parent-node node)))
    (when parent
      (let ((list (doom-node-child-nodes parent))
	    prev
	    done)
	(while (and (not done) list)
	  (if (eq (car list) node)
	      (setq done t)
	    (setq prev (car list)
		  list (cdr list))))
	prev))))
(defalias 'doom-document-previous-sibling 'doom-node-previous-sibling)
(defalias 'doom-element-previous-sibling 'doom-node-previous-sibling)
(defalias 'doom-attr-previous-sibling    'doom-node-previous-sibling)

(defun doom-node-next-sibling (node)
  (let ((parent (doom-node-parent-node node)))
    (when parent
      (nth 1 (memq node (doom-node-child-nodes parent))))))
(defalias 'doom-document-next-sibling 'doom-node-next-sibling)
(defalias 'doom-element-next-sibling 'doom-node-next-sibling)
(defalias 'doom-attr-next-sibling    'doom-node-next-sibling)

;; append-child

;; Adds the node newChild to the end of the list of children of
;; this node. If the newChild is already in the tree, it is
;; first removed.

;; FIXME: newChild of type Node: The node to add.  If it is a DocumentFragment
;; object, the entire contents of the document fragment are moved into
;; the child list of this node

(defun doom-node-append-child (node new-child)
  "Adds NEW-CHILD to the end of the list of children of NODE.
If NEW-CHILD is already in the document tree, it is first removed.
NEW-CHILD will be removed from anywhere in the document!
Return the node added."
  (doom-node-test-new-child node new-child)
  (doom-node-unlink-child-from-parent new-child)
  ;; add new-child at the end of the list
  (let ((children (doom-node-child-nodes node)))
    (setf (doom-node-child-nodes node) (nconc children (list new-child))))
  (setf (doom-node-parent-node new-child) node)
  new-child)
(defalias 'doom-document-append-child 'doom-node-append-child)
(defalias 'doom-element-append-child 'doom-node-append-child)
(defalias 'doom-attr-append-child    'doom-node-append-child)


;; cloneNode

;; Returns a duplicate of this node, i.e., serves as a generic copy
;; constructor for nodes. The duplicate node has no parent; (parentNode
;; is null.).

;; FIXME: Cloning an Element copies all attributes and their values,
;; including those generated by the XML processor to represent defaulted
;; attributes, but this method does not copy any text it contains unless
;; it is a deep clone, since the text is contained in a child Text
;; node. Cloning an Attribute directly, as opposed to be cloned as part
;; of an Element cloning operation, returns a specified attribute
;; (specified is true). Cloning any other type of node simply returns a
;; copy of this node.  (the attribute specified is not implemented)

;; FIXME: Note that cloning an immutable subtree results in a mutable
;; copy, but the children of an EntityReference clone are readonly. In
;; addition, clones of unspecified Attr nodes are specified. And,
;; cloning Document, DocumentType, Entity, and Notation nodes is
;; implementation dependent.  (immutable subtrees not implemented)

;; FIXME: The specification says nothing about nextSibling and
;; previousSibling.  We set these to nil as well, matching parentNode.

(defun doom-node-clone-node (node &optional deep)
  "Return a duplicate of NODE.
The duplicate node has no parent.  Cloning will copy all attributes and
their values, but this method does not copy any text it contains unless
it is a DEEP clone, since the text is contained in a child text node.

When the optional argument DEEP is non-nil, this recursively clones the
subtree under the specified node; if false, clone only the node itself
\(and its attributes, if it has any)."
  ;; We don't want to call this recursively because of performance.
  (let* ((first-copy (copy-doom-node node))
	 (copy first-copy)
	 stack)
    ;; unlink neighbours of the first copy
    (setf (doom-node-parent-node first-copy) nil)
    (while copy
      ;; prevent sharing of text in text nodes
      (let ((value (doom-node-value copy)))
	(when (and value (sequencep value))
	  (setf (doom-node-value copy) (copy-sequence value))))
      ;; copy attributes, and prevent sharing of text in attribute nodes
      (let ((attributes (mapcar 'copy-doom-node (doom-node-attributes copy))))
	(mapc (lambda (attr)
		(let ((value (doom-node-value attr)))
		  (when (and value (sequencep value))
		    (setf (doom-node-value attr) (copy-sequence value)))))
	      attributes)
	(setf (doom-node-attributes copy) attributes))
      (if (not deep)
	  ;; if this is not a deep copy, we are done
	  (setq copy nil)
	;; first clone all children
	(let ((children (mapcar 'copy-doom-node (doom-node-child-nodes copy)))
	      (parent copy))
	  (when children
	    ;; set the children info for the parent
	    (setf (doom-node-child-nodes parent) children)
	    ;; set parent for all children
	    (mapc (lambda (child)
		    (setf (doom-node-parent-node child) parent))
		  children)))
	;; move to the next copy, depth first, storing missed branches
	;; on the stack -- note that "node" continues to refer to the
	;; original node, it should not be used within the while copy
	;; loop!
	(setq copy
	      (cond ((doom-element-first-child copy)
		     (when (doom-element-next-sibling copy)
		       (push (doom-element-next-sibling copy) stack))
		     (doom-element-first-child copy))
		    ((doom-element-next-sibling copy))
		    (t (pop stack))))))
    first-copy))
(defalias 'doom-document-clone-node 'doom-node-clone-node)
(defalias 'doom-element-clone-node 'doom-node-clone-node)
(defalias 'doom-attr-clone-node    'doom-node-clone-node)

;; hasAttributes introduced in DOM Level 2

;; Returns whether this node (if it is an element) has any
;; attributes.

(defun doom-node-has-attributes (node)
  "Return t when NODE has any attributes."
  (not (null (doom-node-attributes node))))
(defalias 'doom-document-has-attributes 'doom-node-has-attributes)
(defalias 'doom-element-has-attributes 'doom-node-has-attributes)
(defalias 'doom-attr-has-attributes    'doom-node-has-attributes)

;; hasChildNodes

;; Returns whether this node has any children.

(defun doom-node-has-child-nodes (node)
  "Return t when NODE has any child nodes."
  (not (null (doom-node-child-nodes node))))
(defalias 'doom-document-has-child-nodes 'doom-node-has-child-nodes)
(defalias 'doom-element-has-child-nodes 'doom-node-has-child-nodes)
(defalias 'doom-attr-has-child-nodes    'doom-node-has-child-nodes)

;; insertBefore

;; Inserts the node newChild before the existing child node refChild. If
;; refChild is null, insert newChild at the end of the list of children.

;; FIXME: If newChild is a DocumentFragment object, all of its children
;; are inserted, in the same order, before refChild. If the newChild is
;; already in the tree, it is first removed.

(defun doom-node-insert-before (node new-child &optional ref-child)
  "Insert NEW-CHILD before NODE's existing child REF-CHILD.
If optional argument REF-CHILD is nil or not given, insert NEW-CHILD at
the end of the list of NODE's children.
If NEW-CHILD is already in the document tree, it is first removed.
NEW-CHILD will be removed from anywhere in the document!
Return the node added."
  ;; without ref-child, append it at the end of the list
  (if (not ref-child)
      (doom-node-append-child node new-child)
    (doom-node-test-new-child node new-child)
    (doom-node-unlink-child-from-parent new-child)
    ;; find the correct position and insert new-child
    (let ((children (doom-node-child-nodes node))
	  child-cell done)
      (while (and (not done) children)
	(if (eq ref-child (car children))
	    (progn
	      ;; if the first child is ref-child, set the list anew
	      (if (not child-cell)
		  (setf (doom-node-child-nodes node)
			(cons new-child children))
		;; else splice new-child into the list
		(setcdr child-cell (cons new-child children)))
	      (setq done t))
	  ;; if we didn't find it, advance
	  (setq child-cell children
		children (cdr children))))
      (unless done
	(doom-exception 'doom-not-found-err)))
    new-child))
(defalias 'doom-document-insert-before 'doom-node-insert-before)
(defalias 'doom-element-insert-before 'doom-node-insert-before)
(defalias 'doom-attr-insert-before    'doom-node-insert-before)

;; removeChild

;; Removes the child node indicated by oldChild from the list of
;; children, and returns it.

(defun doom-node-remove-child (node old-child)
  "Remove OLD-CHILD from the list of NODE's children and return it.
This is very similar to `doom-node-unlink-child-from-parent' but it will
raise an exception if OLD-CHILD is NODE's child."
  (let ((children (doom-node-child-nodes node)))
    (if (memq old-child children)
	(setf (doom-node-child-nodes node) (delq old-child children)
	      (doom-node-parent-node old-child) nil)
      (doom-exception 'doom-not-found-err))
    old-child))
(defalias 'doom-document-remove-child 'doom-node-remove-child)
(defalias 'doom-element-remove-child 'doom-node-remove-child)
(defalias 'doom-attr-remove-child    'doom-node-remove-child)

;; replaceChild

;; Replaces the child node oldChild with newChild in the list of
;; children, and returns the oldChild node.  

;; FIXME: If newChild is a DocumentFragment object, oldChild is replaced
;; by all of the DocumentFragment children, which are inserted in the
;; same order.

;; If the newChild is already in the tree, it is first removed.

(defun doom-node-replace-child (node new-child old-child)
  "Replace OLD-CHILD with NEW-CHILD in the list NODE's children.
Return OLD-CHILD."
  (doom-node-test-new-child node new-child)
  (doom-node-unlink-child-from-parent new-child)
  (let ((children (doom-node-child-nodes node)))
    (unless (memq old-child children)
      (doom-exception 'doom-not-found-err))
    (setf (doom-node-child-nodes node)
	  (cl-nsubstitute new-child old-child children)))
  ;; set parent of new-child and old-child
  (setf (doom-node-parent-node old-child) nil
	(doom-node-parent-node new-child) node))
(defalias 'doom-document-replace-child 'doom-node-replace-child)
(defalias 'doom-element-replace-child 'doom-node-replace-child)
(defalias 'doom-attr-replace-child    'doom-node-replace-child)

;; textContent of type DOOMString, introduced in DOM Level 3

;; This attribute returns the text content of this node and its
;; descendants.

;;  FIXME: When set, any possible children this node may have are
;; removed and replaced by a single Text node containing the string this
;; attribute is set to.  (not implemented yet)

;; On getting, no serialization is performed, the returned string does
;; not contain any markup. Similarly, on setting, no parsing is
;; performed either, the input string is taken as pure textual content.

(defun doom-node-text-content (node)
  "Return the text content of NODE and its children.
If NODE is an attribute or a text node, its value is returned."
  (if (or (doom-attr-p node)
	  (doom-text-p node))
      (doom-node-value node)
    (apply 'concat
	   (mapcar 'doom-node-value
		   (doom-element-get-elements-by-tag-name
		    node doom-text-node-name)))))
(defalias 'doom-document-text-content 'doom-node-text-content)
(defalias 'doom-element-text-content 'doom-node-text-content)
(defalias 'doom-attr-text-content    'doom-node-text-content)

(defun doom-node-set-text-content (node data)
  "Set the text content of NODE, replacing all its children.
If NODE is an attribute or a text node, its value is set."
  (if (or (doom-attr-p node)
	  (doom-text-p node))
      (setf (doom-node-value node) data)
    (setf (doom-node-child-nodes node)
	  (list (doom-document-create-text-node
		 (doom-node-owner-document node)
		 data)))))
(defalias 'doom-document-set-text-content 'doom-node-set-text-content)
(defalias 'doom-element-set-text-content 'doom-node-set-text-content)
(defalias 'doom-attr-set-text-content    'doom-node-set-text-content)

(defsetf doom-node-text-content doom-node-set-text-content)

;;; Utility functions

;; These utility functions are defined for nodes only.

(defun doom-node-ancestor-p (node ancestor)
  "Return t if ANCESTOR is an ancestor of NODE in the tree."
  (let ((parent (doom-node-parent-node node))
	result)
    (while (and (not result) parent)
      (setq result (eq parent ancestor)
	    parent (doom-node-parent-node parent)))
    result))

(defun doom-node-valid-child (node child)
  "Return t if CHILD is a valid child for NODE.
This depends on the node-type of NODE and CHILD."
  ;; FIXME: Add stuff as we go along.
  t)

(defun doom-node-test-new-child (node new-child)
  "Check wether NEW-CHILD is acceptable addition to NODE's children."
  (when (or (doom-node-ancestor-p node new-child)
	    (eq new-child node)
	    (not (doom-node-valid-child node new-child)))
    (doom-exception 'doom-hierarchy-request-err))
  (when (not (eq (doom-node-owner-document node)
		 (doom-node-owner-document new-child)))
    (doom-exception 'doom-wrong-document-err))
  new-child)

(defun doom-node-unlink-child-from-parent (node)
  "Unlink NODE from is previous location.
This is very similar to `doom-node-remove-child' but it will check wether
this node is the child of a particular other node."
  ;; remove node from it's old position
  (let ((parent (doom-node-parent-node node)))
    (when parent
      ;; remove from parent's child-nodes and set own parent to nil
      (setf (doom-node-child-nodes parent)
	    (delq node (doom-node-child-nodes parent))
	    (doom-node-parent-node node)
	    nil)))
  node)

;;; Interface NodeList

;; The NodeList interface provides the abstraction of an ordered
;; collection of nodes, without defining or constraining how this
;; collection is implemented. NodeList objects in the DOM are live.

;; The items in the NodeList are accessible via an integral index,
;; starting from 0.

;; This provides alternate names for plain lisp list accessor functions.

(defalias 'doom-node-list-length 'length)

(defun doom-node-list-item (list index); for the sake of argument order
  "Return element at INDEX in LIST.
Equivalent to (nth INDEX NODE)."
  (nth index list))

;; Interface Attr

;; The Attr interface represents an attribute in an Element object.
;; Typically the allowable values for the attribute are defined in a
;; document type definition.

;; Attr objects inherit the Node interface, but since they are not
;; actually child nodes of the element they describe, the DOM does not
;; consider them part of the document tree. Thus, the Node attributes
;; parentNode, previousSibling, and nextSibling have a null value for Attr
;; objects. The DOM takes the view that attributes are properties of
;; elements rather than having a separate identity from the elements they
;; are associated with; this should make it more efficient to implement
;; such features as default attributes associated with all elements of a
;; given type. Furthermore, Attr nodes may not be immediate children of a
;; DocumentFragment. However, they can be associated with Element nodes
;; contained within a DocumentFragment. In short, users and implementors
;; of the DOM need to be aware that Attr nodes have some things in common
;; with other objects inheriting the Node interface, but they also are
;; quite distinct.

;; The attribute's effective value is determined as follows: if this
;; attribute has been explicitly assigned any value, that value is the
;; attribute's effective value; otherwise, if there is a declaration for
;; this attribute, and that declaration includes a default value, then
;; that default value is the attribute's effective value; otherwise, the
;; attribute does not exist on this element in the structure model until
;; it has been explicitly added. Note that the nodeValue attribute on the
;; Attr instance can also be used to retrieve the string version of the
;; attribute's value(s).

;; In XML, where the value of an attribute can contain entity references,
;; the child nodes of the Attr node may be either Text or EntityReference
;; nodes (when these are in use; see the description of EntityReference
;; for discussion). Because the DOM Core is not aware of attribute types,
;; it treats all attribute values as simple strings, even if the DTD or
;; schema declares them as having tokenized types.

;; ownerElement of type Element, readonly, introduced in DOM Level 2

;; The Element node this attribute is attached to or null if
;; this attribute is not in use.

;; Interface Element

;; The Element interface represents an element in an HTML or XML
;; document.  Elements may have attributes associated with them; since
;; the Element interface inherits from Node, the generic Node interface
;; attribute attributes may be used to retrieve the set of all
;; attributes for an element. There are methods on the Element interface
;; to retrieve either an Attr object by name or an attribute value by
;; name. In XML, where an attribute value may contain entity references,
;; an Attr object should be retrieved to examine the possibly fairly
;; complex sub-tree representing the attribute value. On the other hand,
;; in HTML, where all attributes have simple string values, methods to
;; directly access an attribute value can safely be used as a
;; convenience.

(defun doom-element-get-elements-by-tag-name-1 (element name)
  "Return a list of elements with tag NAME.
The elements are ELEMENT, its siblings, and their descendants.
This is used by `doom-element-get-elements-by-tag-name' and
`doom-document-get-elements-by-tag-name'."
  ;; We don't want to call this recursively because of performance.
  (let (stack result)
    (while element
      (when (or (string= name "*")
		(string= name (doom-node-name element)))
	(setq result (cons element result)))
      (setq element
	    (cond ((doom-node-first-child element)
		   (when (doom-node-next-sibling element)
		     (push (doom-node-next-sibling element) stack))
		   (doom-node-first-child element))
		  ((doom-node-next-sibling element))
		  (t (pop stack)))))
    (nreverse result)))

(defun doom-element-get-elements-by-tag-name (element name)
  "Return a list of all descendant of ELEMENT with tag NAME.
The elements are returned in the order in which they are encountered in
a preorder traversal of this element tree."
  (doom-element-get-elements-by-tag-name-1
   (doom-element-first-child element)
   name))

;; Interface Text

;; The Text interface inherits from CharacterData and represents the
;; textual content (termed character data in XML) of an Element or Attr.
;; If there is no markup inside an element's content, the text is
;; contained in a single object implementing the Text interface that is
;; the only child of the element. If there is markup, it is parsed into
;; the information items (elements, comments, etc.) and Text nodes that
;; form the list of children of the element.

;; When a document is first made available via the DOM, there is only one
;; Text node for each block of text. Users may create adjacent Text nodes
;; that represent the contents of a given element without any intervening
;; markup, but should be aware that there is no way to represent the
;; separations between these nodes in XML or HTML, so they will not (in
;; general) persist between DOM editing sessions. The normalize() method
;; on Node merges any such adjacent Text objects into a single node for
;; each block of text.

;; Character data is represented as a plain string.



;;; Converting XML to DOM

;; Converting XML (hierarchy of nodes, simple lists, symbols and
;; strings) to DOM (hierarchy of doom-nodes, cl-defstructs from CL)

(defun doom-make-attribute-from-xml (attribute element doc)
  "Make a DOM node of attributes based on ATTRIBUTE.
Called from `doom-make-element-from-xml'.
ELEMENT is the owner-element.
DOC is the owner-document."
  (let* ((name (car attribute))
	 (value (cdr attribute))
	 (attr (doom-document-create-attribute doc name)))
    (setf (doom-attr-value attr) value
	  (doom-attr-owner-element attr) element)
    attr))

(defun doom-add-children (parent children)
  "Add CHILDREN to PARENT.
CHILDREN is a list of XML NODE elements.  Each must
be converted to a doom-node first."
  (when children
    (setf (doom-node-child-nodes parent)
	  (mapcar (lambda (child)
		    (doom-make-node-from-xml
		     child
		     (doom-node-owner-document parent)))
		  children))
    (mapc (lambda (child)
	    (setf (doom-node-parent-node child)
		  parent))
	  (doom-node-child-nodes parent))))

(defun doom-make-element-from-xml (node owner)
  "Make a DOM element based on NODE.
Called from `doom-make-node-from-xml'.
The atttributes are created by `doom-make-attribute-from-xml'.
OWNER is stored as the owner-document."
  (let* ((children (xml-node-children node))
	 (attributes (xml-node-attributes node))
	 (type (xml-node-name node))
	 (element (doom-document-create-element owner type)))
    (when attributes
      (setf (doom-node-attributes element)
	    (mapcar (lambda (attribute)
		      (doom-make-attribute-from-xml attribute element owner))
		    attributes)))
    (when children
      (doom-add-children element children))
    element))

(defun doom-make-node-from-xml (node owner)
  "Make a DOM node based on NODE.
If NODE is a list, the node is created by `doom-make-element-from-xml'.
OWNER is stored as the owner-document."
  (cond ((stringp node)
	 (doom-document-create-text-node owner node))
	((listp node)
	 (doom-make-element-from-xml node owner))
	(t
	 (error "Illegal node: %S" node))))

(defun doom-make-document-from-xml (node)
  "Return a DOM document based on NODE.
NODE is a node as returned by `libxml-parse-xml-region'.  
The DOM nodes are created using `doom-make-node-from-xml'.

Example:
       (let ((doc (doom-make-document-from-xml 
                  (with-temp-buffer
  		    (insert-file-contents \"sample.xml\")
  		    (libxml-parse-xml-region 
                      (point-min) (point-max)))))))
"
  (let* ((doc (make-doom-document
	       :name doom-document-node-name
	       :type doom-document-node))
	 (node (doom-make-node-from-xml node doc)))
    (setf (doom-document-owner-document doc) doc; required in doom-add-children
	  (doom-document-element doc) node)
    doc))

(provide 'doom)

;;; doom.el ends here.
