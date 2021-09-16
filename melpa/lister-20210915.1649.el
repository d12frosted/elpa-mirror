;;; lister.el --- Yet another list printer             -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2021

;; Author:  <joerg@joergvolbers.de>
;; Version: 0.9
;; Package-Version: 20210915.1649
;; Package-Commit: 3d3fcc9293aaaa84994ea38a38d986a29545f425
;; Package-Requires: ((emacs "26.1"))
;; Keywords: lisp
;; URL: https://github.com/publicimageltd/lister

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

;; A library for creating interactive list buffers.

;;; Code:
(require 'cl-lib)
(require 'ewoc)

;;; * Global Variables

(defvar-local lister-local-filter nil
  "Buffer local filter predicate for Lister lists.
Do not set this directly; use `lister-set-filter' instead.")

(defcustom lister-default-left-margin 2
  "Default padding for every item."
  :group 'lister
  :type 'integer)

(defcustom lister-mark-face-or-property
  '(:background "darkorange3"
                :foreground "white")
  "Text properties to be added when highlighting marked items.
Possible values are either a plist of face attributes or the name
of a face."
  :group 'lister
  :type '(choice (face :tag "Name of a face")
                 (plist :tag "Plist of face attributes")))

;;; * Buffer Local Variables

(defvar-local lister-local-mapper nil
  "Buffer local mapper function for printing lister list items.
The mapper function converts a data object (any kind of list
object) to a list of strings, which will then be inserted as a
representation of that data.")

;;; * Data Types

(cl-defstruct (lister--item (:constructor lister--item-create))
  "The list item plus some additional extra informations.
The slot DATA contains the 'real' data, which is printed using
  the mapper."
  level marked invisible beg end data)

(defun lister--item-visible (item-struct)
  "For ITEM-STRUCT, get negated value of of `lister--item-invisible'."
  (not (lister--item-invisible item-struct)))

;;; * Helper

;; use this instead of flatten-tree for emacsen < 27.1:
(defun lister--flatten (l)
  "Flatten the list L, removing any null values.
This is a simple copy of dash's `-flatten' using `seq'."
  (if (and (listp l) (listp (cdr l)))
      (seq-mapcat #'lister--flatten l)
    (list l)))

;;; * Low-level printing / insertion:
;;;

;; Insert the item strings:

(defun lister--insert-intangible (strings padding-level)
  "In current buffer, insert all STRINGS with text property 'intangible'.
Insert a newline after each single string in STRINGS.  Pad all
strings according to PADDING-LEVEL and the buffer local value of
`lister-default-left-margin'."
  (when strings
    (let* ((padding-string (make-string (+ lister-default-left-margin (or padding-level 0)) ? ))
           (strings        (mapcar (apply-partially #'concat padding-string)
                                   strings)))
      ;; Assumes rear-stickiness.
      (insert (propertize (string-join strings "\n")
                          'cursor-intangible t
                          'field t)
              "\n")))) ;; <- this leaves the "tangible" gap for the next item!

(defun lister--insert-as-hf (strings)
  "In current buffer, insert STRINGS as header or footer.
This basically means that there will be no gap to place the
cursor on, so that this item cannot be moved to."
  (when strings
    (let ((beg (point)))
      (lister--insert-intangible strings (- 0 lister-default-left-margin))
      (put-text-property beg (1+ beg) 'front-sticky t))))

(defun lister--set-h-or-f (ewoc h-or-f strings)
  "Set STRINGS as list header or footer in EWOC.
If H-OR-F is t, set STRINGS as a header, else as a footer.
STRINGS can be a string or a list of strings."
  (let* ((strings (if (stringp strings) (list strings) strings))
         (hf      (ewoc-get-hf ewoc))
         (new-hf  (if h-or-f (list strings (cdr hf))
                    (list (car hf) strings))))
    (apply #'ewoc-set-hf ewoc new-hf)))

(defun lister-set-header (ewoc strings)
  "Set STRINGS as a list header in EWOC.
STRINGS can be a string or a list of strings."
  (lister--set-h-or-f ewoc t strings))

(defun lister-set-footer (ewoc strings)
  "Set STRINGS as a list header in EWOC.
STRINGS can be a string or a list of strings."
  (lister--set-h-or-f ewoc nil strings))

;; Make the item invisible / visible:

(defun lister--invisibilize-item (item value)
  "For ITEM in current buffer, set the property 'invisible' to VALUE.
Respect the cursor gap so that the user cannot navigate to
invisible items.  The VALUE t hides the item, nil makes it
visible."
  (let* ((inhibit-read-only t)
         (beg   (lister--item-beg item))
         (end   (lister--item-end item))
         ;; we don't want to store any values, just t or nil:
         (value (not (not value))))
    ;;
    (put-text-property beg end 'invisible value)
    ;; this opens or closes the gap for the marker:
    (put-text-property beg (1+ beg) 'front-sticky value)
    ;; store the status in the lister item:
    (setf (lister--item-invisible item) value)))

(defun lister--invisibilize-node (node value)
  "For NODE in current buffer, set the property 'invisible' to VALUE.
Respect the cursor gap so that the user cannot navigate to
invisible items.  The VALUE t hides the item, nil makes it
visible."
  (lister--invisibilize-item (ewoc-data node) value))

;; Mark / unmark the item:

(defun lister--add-face-property (beg end value &optional append)
  "Add VALUE to the face property between BEG and END."
  (add-face-text-property beg end value append))

(defun lister--remove-face-property (beg end value)
  "Remove VALUE from the face property from BEG to END.
This is a slightly modified copy of `font-lock--remove-face-from-text-property'."
  (let ((beg (text-property-not-all beg end 'face nil))
        next prev)
    (while beg
      (setq next (next-single-property-change beg 'face nil end)
            prev (get-text-property beg 'face))
      (cond ((or (atom prev)
                 (keywordp (car prev))
                 (eq (car prev) 'foreground-color)
                 (eq (car prev) 'background-color))
             (when (eq value prev)
               (remove-list-of-text-properties beg next (list 'face))))
            ((memq value prev)		;Assume prev is not dotted.
             (let ((new (remq value prev)))
               (cond ((null new)
                      (remove-list-of-text-properties beg next (list 'face)))
                     ((= (length new) 1)
                      (put-text-property beg next 'face (car new)))
                     (t
                      (put-text-property beg next 'face new))))))
      (setq beg (text-property-not-all next end 'face nil)))))

(defun lister--update-mark-state (item)
  "Modify ITEM according to its marked state."
  (let* ((inhibit-read-only t)
         (beg (lister--item-beg item))
         (end (lister--item-end item)))
    (if (lister--item-marked item)
        (lister--add-face-property beg end lister-mark-face-or-property)
      (lister--remove-face-property beg end lister-mark-face-or-property))))

;; The actual printer for the ewoc:

;; NOTE Does storing three markers in each node
;; (ewoc--node-start-marker,beg and end) lead to a performance
;; problem?
(defun lister--ewoc-printer (item)
  "Insert pretty printed ITEM in the current buffer.
ITEM is a `lister--item'.  Build the item by passing it to the
buffer local mapper function, which must return a string or a
list of strings."
  (unless lister-local-mapper
    (error "No buffer local mapper function defined"))
  (let* ((inhibit-read-only t)
         (strings (funcall lister-local-mapper (lister--item-data item)))
         ;; make sure STRINGS is a list:
         (strings   (if (listp strings) strings (list strings)))
         ;; flatten it and remove nil values:
         (strings   (lister--flatten strings))
         (beg (point-marker)))
    (lister--insert-intangible strings (lister--item-level item))
    ;; store positions for post-insertion modifications
    (setf (lister--item-beg item) beg
          (lister--item-end item) (point-marker))
    ;; maybe display marker:
    (when (lister--item-marked item)
      (lister--update-mark-state item))
    ;; maybe hide item:
    (when (and lister-local-filter
               (funcall lister-local-filter (lister--item-data item))
               (not (lister--item-invisible item)))
      (lister--invisibilize-item item t))))

(defun lister--parse-position (ewoc pos)
  "Return node according to POS in EWOC.
POS can be one of the symbols `:point', `:first', `:next',
`:prev', `:last', or an integer indicating the nth node counting
from 0.  All positions refer to the actual list; any filtering is
ignored.

If POS is a node, pass it through.

If POS is neither a node, nor an integer, nor one of the symbols
above, throw an error."
  ;; ewoc-locate uses (point) without checking the current buffer,
  ;; so we do it instead:
  (with-current-buffer (ewoc-buffer ewoc)
    (pcase pos
      (:first   (ewoc-nth ewoc 0))
      (:last    (ewoc-nth ewoc -1))
      (:point   (ewoc-locate ewoc))
      (:next    (ewoc-next ewoc (ewoc-locate ewoc)))
      (:prev    (ewoc-prev ewoc (ewoc-locate ewoc)))
      ((pred integerp) (or (ewoc-nth ewoc pos)
                           (error "Index out of bounds: %d" pos)))
      ;; I couldn't find any predicate ewoc--node-p or alike, even
      ;; though ewoc--node is defined as a cl struct. So we do some
      ;; very minimal testing only:
      ((pred vectorp)   pos)
      (_        (error "Unkown position argument: %s" pos)))))

(defun lister--determine-level (prev-level new-level)
  "Return the level for new items relative to PREV-LEVEL.
If PREV-LEVEL is nil, assume the new item to be a top item.
NEW-LEVEL can be nil or an integer requesting a level.  Return
the level value which is appropriate considering the value of
PREV-LEVEL."
  (max 0
       (cond
        ((null prev-level)         0) ;; top item: always indent with 0
        ((null new-level)          prev-level)
        ((> new-level prev-level) (1+ prev-level))
        (t                         new-level))))

(defun lister--debug-nodes (&rest nodes)
  "Return only the items contained in NODES."
  (mapcar #'ewoc-data (lister--flatten nodes)))

;;; * Low level list movement basics

(cl-defun lister--next-node-matching (ewoc node pred-fn
                                        &optional (move-fn #'ewoc-next))
  "In EWOC, move from NODE to next node matching PRED-FN via MOVE-FN.
Return the next matching node or nil if there is none.  To move
backwards, set MOVE-FN to `ewoc-prev'."
  (while (and node
              (setq node (funcall move-fn ewoc node))
              (not (funcall pred-fn node))))
  node)

(cl-defun lister--next-or-this-node-matching (ewoc node pred-fn
                                                &optional (move-fn #'ewoc-next))
  "In EWOC, check NODE against PRED-FN or find next match.
Return the matching node found by iterating on MOVE-FN, or nil if
there is none.  To move backwards, set MOVE-FN to `ewoc-prev'."
  (if (funcall pred-fn node)
      node
    (lister--next-node-matching ewoc node pred-fn move-fn)))

(cl-defun lister--next-visible-node (ewoc node &optional
                                       (move-fn #'ewoc-next))
  "In EWOC, move from NODE to next visible node via MOVE-FN.
Return the next node or nil if there is none.  To move backwards,
set MOVE-FN to `ewoc-prev'."
  (lister--next-node-matching ewoc node #'lister-node-visible-p move-fn))

(defun lister--first-visible-node (ewoc &optional node)
  "Find the first visible node in EWOC, beginning with NODE.
If NODE is nil, return the first visible node of the EWOC."
  (lister--next-or-this-node-matching ewoc (or node (ewoc-nth ewoc 0))
                                   #'lister-node-visible-p))

(defun lister--last-visible-node (ewoc &optional node)
  "Find the last visible node in EWOC, beginning with NODE.
If NODE is nil, return the last visible node of the EWOC."
  (lister--next-or-this-node-matching ewoc (or node (ewoc-nth ewoc -1))
                                   #'lister-node-visible-p
                                   #'ewoc-prev))

;;; * Public API

(defmacro lister-with-region (ewoc beg-var end-var &rest body)
  "In EWOC, do BODY binding BEG-VAR and END-VAR to list boundaries.
BEG and END have to be variable names.  When executing BODY, bind
BEG and END to the items indicated by the current value of these
variables.  All values understood by `lister--parse-position' are
accepted.  If either variable is nil at runtime or yet unbound,
bind it to very first or to the very last node, respectively.

Do nothing if list is empty."
  (declare (indent 3) (debug (sexp symbolp symbolp body)))
  (unless (and (symbolp beg-var) (not (keywordp beg-var)))
    (signal 'wrong-type-argument (list 'symbolp beg-var)))
  (unless (and (symbolp end-var) (not (keywordp end-var)))
    (signal 'wrong-type-argument (list 'symbolp end-var)))
  `(when-let ((,beg-var (lister--parse-position ,ewoc (or ,beg-var :first)))
              (,end-var (lister--parse-position ,ewoc (or ,end-var :last))))
       ,@body))

;; * Basic Loop Macros

(defmacro lister-dolist-nodes (spec &rest body)
  "In EWOC, execute BODY looping over a list of nodes.
The first argument SPEC is a list with the following arguments:

 EWOC  - An ewoc object.
 VAR   - A variable which is bound to the current node in the loop.
 [BEG] - Optionally a beginning node, or a position which can be
         parsed by `lister--parse-position'.
 [END] - Optionally a final node, or a position.

If BEG or END are not provided or nil, use the first or the last
item of the list, respectively.

The node bound to VAR can be safely destroyed without quitting
the loop.

\(fn (EWOC VAR [BEG] [END]) BODY...)"
  (declare (indent 1) (debug ((sexp symbolp &optional sexp sexp)
                              body)))
  (unless (consp spec)
    (signal 'wrong-type-argument (list 'consp spec)))
  (unless (<= 2 (length spec) 4)
    (signal 'wrong-number-of-arguments (list '(2 . 4) (length spec))))
  (let ((ewoc     (nth 0 spec))
        (node-sym (nth 1 spec))
        (beg      (nth 2 spec))
        (end      (nth 3 spec))
        (temp-node (make-symbol "--temp-node--"))
        (last-var  (make-symbol "--last-node--")))
    (unless (symbolp node-sym)
      (signal 'wrong-type-argument (list 'symbolp node-sym)))
    `(let ((,node-sym (lister--parse-position ,ewoc (or ,beg :first)))
           (,last-var (lister--parse-position ,ewoc (or ,end :last))))
       (while ,node-sym
         ;; get the next node before BODY, since BODY might delete
         ;; the current node pointer:
         (let ((,temp-node (ewoc-next ,ewoc ,node-sym)))
           ,@body
           (setq ,node-sym (unless (eq ,node-sym ,last-var)
                             ,temp-node)))))))

(cl-defmacro lister-dolist (spec &rest body)
  "In EWOC, execute BODY looping over a list of item data.
The first argument SPEC is a list with the following arguments:

 EWOC  - An ewoc object.
 VAR   - A variable which is bound to the current data in the loop.
 [BEG] - Optionally a beginning node, or a position which can be
         parsed by `lister--parse-position'.
 [END] - Optionally a final node, or a position.
 [NODE-VAR] - Optionally bind the data's node.

If BEG or END are not provided or nil, use the first or the last
item of the list, respectively.

\(fn (EWOC VAR [BEG] [END] [NODE-VAR]) BODY...)"
  (declare (indent 1) (debug ((sexp symbolp &optional sexp sexp symbolp)
                              body)))
  (unless (consp spec)
    (signal 'wrong-type-argument (list 'consp spec)))
  (unless (<= 2 (length spec) 5)
    (signal 'wrong-number-of-arguments (list '(2 . 5) (length spec))))
  (let ((ewoc     (nth 0 spec))
        (data-sym (nth 1 spec))
        (node-sym (or (nth 4 spec) (make-symbol "--node--"))))
    (unless (symbolp data-sym)
      (signal 'wrong-type-argument (list 'symbolp data-sym)))
    (unless (symbolp node-sym)
      (signal 'wrong-type-argument (list 'symbolp node-sym)))
    `(lister-dolist-nodes (,ewoc ,node-sym ,(nth 2 spec) ,(nth 3 spec))
       (let ((,data-sym (lister--item-data (ewoc-data ,node-sym))))
         ,@body))))

;; * More Specific Loop Functions

(defun lister-collect-list (ewoc &optional beg end pred-fn map-fn)
  "In EWOC, collect and optionally transform all data between BEG and END.
BEG and END are positions understood by `lister--parse-position'
and point to the first or the last node to be considered.  If
nil, use the first or the last node of the complete list instead.
If PRED-FN is set, only consider those nodes for which PRED-FN,
when called with the node's data, returns true.  If MAP-FN is
set, call MAP-FN on the node's data before collecting it."
  (let (acc)
    (lister-dolist (ewoc data beg end)
      (when (or (not pred-fn)
                (funcall pred-fn data))
        (push (funcall (or map-fn #'identity) data) acc)))
    (nreverse acc)))

(defun lister-collect-nodes (ewoc &optional beg end pred-fn map-fn)
  "In EWOC, collect and optionally transform all nodes between BEG and END.
Return all nodes between BEG and END.  BEG and END are positions
understood by `lister--parse-position' and point to the first or
the last node to be considered.  If nil, use the first or the
last node of the complete list instead.  When PRED-FN is set,
only return those nodes for which PRED-FN, called with the node,
returns true.  If MAP-FN is set, call MAP-FN on the node before
collecting it."
  (let (acc)
    (lister-dolist-nodes (ewoc node beg end)
      (when (or (not pred-fn)
                (funcall pred-fn node))
        (push (funcall (or map-fn #'identity) node) acc)))
    (nreverse acc)))

(defun lister-update-list (ewoc action-fn &optional beg end pred-fn)
  "Apply ACTION-FN on each item's data and redisplay it.
In EWOC, call ACTION-FN on each item data within the node
positions BEG and END.  If BEG or END is nil, use the first or
the last node instead.

ACTION-FN is called with one argument, the item's data.  Update
the item if ACTION-FN returns a non-nil value.  If PRED-FN is
set, restrict action only to matching nodes."
  (let (new-data)
    (lister-dolist (ewoc data beg end node)
      (when (and (or (not pred-fn)
                     (funcall pred-fn data))
                 (setq new-data (funcall action-fn (cl-copy-seq data))))
        (setf (lister--item-data (ewoc-data node)) new-data)
        (ewoc-invalidate ewoc node)))))

(defun lister-walk-nodes (ewoc action-fn &optional beg end pred-fn)
  "Call ACTION-FN on each item's node.
In EWOC, call ACTION-FN on each item's node within the node
positions BEG and END.  If BEG or END is nil, use the first or
the last node instead.

ACTION-FN is called with two arguments: the EWOC and the node.
It is up to ACTION-FN to redisplay the node.  If PRED-FN is set,
restrict action only to matching nodes."
  (lister-dolist-nodes (ewoc node beg end)
    (when (or (not pred-fn)
              (funcall pred-fn node))
      (funcall action-fn ewoc node))))

;; * Check the whole list

(defun lister-empty-p (ewoc)
  "Return t if EWOC has no list."
  (null (ewoc-nth ewoc 0)))

(defun lister-point-min (ewoc)
  "Return the start position of the very first item in EWOC.
This is the position after the header."
  (ewoc--node-start-marker (ewoc--header ewoc)))

(defun lister-point-max (ewoc)
  "Return the end position of the very last item in EWOC.
This is one character before the beginning of the footer."
  (1- (ewoc--node-start-marker (ewoc--footer ewoc))))

;; * Goto Nodes

(defun lister-goto (ewoc pos)
  "In EWOC, move point to POS.
POS can be either an ewoc node, an index position, or one of the
symbols `:first', `:last', `:point' (sic!), `:next' or `:prev'.

Do nothing if position does not exist; throw an error if position
is invalid (i.e. index is out of bounds) or invisible."
  ;; NOTE This is a common pattern: when-let node, do something with
  ;; node, else error. Refactor?
  (when-let ((node (lister--parse-position ewoc pos)))
    (if (lister--item-visible (ewoc-data node))
        (ewoc-goto-node ewoc node)
      (error "Cannot go to invisible item %s" pos))))

;; * Inspect Nodes

(defalias 'lister-get-node-at 'lister--parse-position)

(defun lister-node-get-level (node)
  "Get the indentation level of NODE."
  (lister--item-level (ewoc-data node)))

(defun lister-set-node-level (ewoc node level)
  "In EWOC, set indentation of NODE to LEVEL, refreshing it."
  (setf (lister--item-level (ewoc-data node)) level)
  (ewoc-invalidate ewoc node))

(defun lister-get-level-at (ewoc pos)
  "In EWOC, get the indentation level of the item at POS."
  (when-let ((node (lister--parse-position ewoc pos)))
    (lister-node-get-level node)))

(defun lister-set-level-at (ewoc pos level)
  "In EWOC, set indentation of node at POS to LEVEL, refreshing it."
  (lister-set-node-level ewoc (lister--parse-position ewoc pos) level))

(defun lister-node-get-data (node)
  "Get the item data stored in NODE."
  (lister--item-data (ewoc-data node)))

(defun lister-get-data-at (ewoc pos)
  "In EWOC, return the data of the lister node at POS.
POS can be either an ewoc node, an index position, or one of the
symbols `:first', `:last', `:point', `:next' or `:prev'."
  (if-let ((node (lister--parse-position ewoc pos)))
      (lister-node-get-data node)
    (error "No node or lister item at position %s" pos)))

(defun lister-set-data-at (ewoc pos data)
  "In EWOC, replace the data at POS with DATA."
  (let ((node (lister--parse-position ewoc pos)))
    (unless node
      (error "No node or lister item at position %s" pos))
    (setf (lister--item-data (ewoc-data node)) data)
    (ewoc-invalidate ewoc node)))

(defalias 'lister-replace-at 'lister-set-data-at)

(defun lister-node-visible-p (node)
  "In EWOC, test if NODE is visible."
  (lister--item-visible (ewoc-data node)))

(defalias 'lister-item-visible-p 'lister--item-visible)

(defun lister-node-marked-p (node)
  "In EWOC, test if NODE is in a marked state."
  (lister--item-marked (ewoc-data node)))

(defalias 'lister-item-marked-p 'lister--item-marked)

(defun lister-node-marked-and-visible-p (node)
  "In EWOC, test if NODE is marked and visible."
  (let ((item (ewoc-data node)))
    (and (lister--item-marked item)
         (lister--item-visible item))))

;; * Delete Items

(defun lister-delete-at (ewoc pos)
  "In EWOC, delete node specified by POS."
  (let* ((node (lister--parse-position ewoc pos))
         (inhibit-read-only t))
    (ewoc-delete ewoc node)))

(defun lister-delete-list (ewoc beg end)
  "In EWOC, delete all nodes from BEG up to END.
BEG and END is a node or a position, or nil standing for the
first or the last node, respectively."
  (let* ((inhibit-read-only t)
         (nodes (lister-collect-nodes ewoc beg end)))
    (apply #'ewoc-delete ewoc nodes)))

(defun lister-delete-all (ewoc)
  "Delete all items in EWOC."
  (lister-delete-list ewoc :first :last))

;; * Redisplay items

(defun lister-refresh-at (ewoc pos)
  "In EWOC, redisplay the node at POS."
  (when-let ((node (lister--parse-position ewoc pos)))
    (ewoc-invalidate ewoc node)))

(defun lister-refresh-list (ewoc beg end)
  "In EWOC, redisplay the nodes from BEG to END."
  (when-let ((nodes (lister-collect-nodes ewoc beg end)))
    (apply #'ewoc-invalidate ewoc nodes)))

;; * Marking

(defun lister-mark-unmark-at (ewoc pos state)
  "In EWOC, mark or unmark node at POS using boolean STATE."
  (when-let ((node (lister--parse-position ewoc pos)))
    (let* ((item      (ewoc-data node))
           (old-state (lister--item-marked item)))
      (setf (lister--item-marked item) state)
      (when (not (eq old-state state))
        (with-current-buffer (ewoc-buffer ewoc)
          (lister--update-mark-state item))))))

(defun lister-mark-unmark-list (ewoc beg end state)
  "In EWOC, mark or unmark the list between BEG and END.
If boolean STATE is true, the node are taken to be 'marked'.  BEG
and END can be nodes, positions such as `:first', `:point' or
`:last', or indices."
  (lister-dolist-nodes (ewoc node beg end)
    (lister-mark-unmark-at ewoc node state)))

(defun lister-get-marked-list (ewoc &optional beg end marker-pred-fn do-not-flatten-list)
  "In EWOC, get all items which are marked and visible.
BEG and END refer to the first and last node to be checked,
defaulting to the first and last node of the list.  Return a flat
list of all marked items.

Per default, return those items which are marked and visible.
Alternative predicates can be passed to MARKER-PRED-FN.

Return a flattened list with all items matching MARKER-PRED-FN.  If
DO-NOT-FLATTEN-LIST is non-nil, respect hierarchy levels."
  (let ((l (lister-get-list ewoc beg end 0
                            (or marker-pred-fn #'lister-node-marked-and-visible-p))))
    (if (not do-not-flatten-list)
        (lister--flatten l)
      l)))

(defun lister-walk-marked-nodes (ewoc action-fn &optional beg end marker-pred-fn)
  "In EWOC, call ACTION-FN on each node which is marked and visible.
BEG and END refer to the first and last node to be checked,
defaulting to the first and last node of the list.

Call ACTION-FN with the EWOC as its first and the current node as
the second argument.

Per default, only consider those items which are marked and
visible.  Alternative predicates can be passed to MARKER-PRED-FN."
  (lister-walk-nodes ewoc action-fn beg end
                     (or marker-pred-fn #'lister-node-marked-and-visible-p)))

(defun lister-walk-marked-list (ewoc action-fn &optional beg end marker-pred-fn)
  "In EWOC, call ACTION-FN on each data which is marked and visible.
BEG and END refer to the first and last node to be checked,
defaulting to the first and last node of the list.

Call ACTION-FN with the current list item's data as its sole
argument.

Per default, only consider those items which are marked and
visible.  Alternative predicates can be passed to MARKER-PRED-FN.

Note that unlike ACTION-FN, the predicate MARKER-PRED-FN is
called with the current node, not the data!"
  (let ((pred-fn (or marker-pred-fn #'lister-node-marked-and-visible-p)))
    (lister-dolist (ewoc data beg end node)
      (when (funcall pred-fn node)
        (funcall action-fn data)))))

(defun lister-delete-marked-list (ewoc &optional beg end marker-pred-fn)
  "In EWOC, delete marked and visible items between BEG and END.
BEG and END refer to the first and last node to be checked,
defaulting to the first and last node of the list.

Per default, only consider those items which are marked and
visible.  Alternative predicates can be passed to MARKER-PRED-FN."
  (let* ((inhibit-read-only t)
         (pred-fn (or marker-pred-fn #'lister-node-marked-and-visible-p))
         (nodes   (lister-collect-nodes ewoc beg end pred-fn)))
    (apply #'ewoc-delete ewoc nodes)))

;; * Insert Items

(defun lister--walk-insert (ewoc tail level node)
  "In EWOC, recursively insert all elements of TAIL.
The items are inserted from the bottom to top, that is, they are
'stacked' either on NODE or, if NODE is nil, on the bottom of the
list.  Insertion starts with indentation level LEVEL; nested
lists are inserted with an higher indentation level."
  (let (item)
    (while tail
      (setq item (car tail)
            tail (cdr tail))
      (if (listp item)
          (lister--walk-insert ewoc item (1+ level) node)
        ;; wrap the item in an item object:
        (setq item (lister--item-create :level level
                                     :data  item))
        (if node
            (ewoc-enter-before ewoc node item)
          (ewoc-enter-last ewoc item))))))

(defun lister-insert-list (ewoc pos data-list &optional
                            level insert-after)
  "In EWOC, insert DATA-LIST as printed items at POS.
POS can be either an ewoc node, an index position, or one of the
symbols `:first', `:last', `:point', `:next' or `:prev'.

If DATA-LIST is a nested list, also indent the printed items
according to the nesting level.  Note that since nesting is
marked by cons cells, a single data item cannot be itself a list
structure!  Use a vector or a `cl-defstruct' instead, if you need
to store more than one value in one data item.

If LEVEL is nil, align the new data item's level with its
predecessor.  If LEVEL is an integer value, indent the item LEVEL
times.  Silently correct invalid values, e.g. positive ones at
the beginning of the list.

Insert data-list before (or visually 'above') the node at POS,
unless INSERT-AFTER is set."
  (let* (;; determine the level:
         (node (lister--parse-position ewoc pos))
         (prev (if insert-after node (ewoc-prev ewoc node)))
         (prev-level (if prev (lister--item-level (ewoc-data prev))      0))
         (this-level (if prev (lister--determine-level prev-level level) 0)))
    ;; Per default, lister--walk-insert inserts before NODE. Adjust
    ;; the other cases to that scheme:
    (cond
     ((and (null node) insert-after)      ;; insert at top?
      (setq node (ewoc-nth ewoc 0)))      ;; => insert before the first item
     ((and node insert-after)             ;; insert after NODE?
      (setq node (ewoc-next ewoc node)))) ;; => insert before its next node
    ;;
    (lister--walk-insert ewoc data-list this-level node)))

(defun lister-insert (ewoc pos data  &optional level insert-after)
  "In EWOC, insert DATA at POS, printing it.
POS can be either an ewoc node, an index position, or one of the
symbols `:first', `:last', `:point', `:next' or `:prev'.

If LEVEL is nil, align the new data item's level with its
predecessor.  If LEVEL is an integer value, indent the item LEVEL
times.  Silently correct invalid values, e.g. positive ones at
the beginning of the list.

Insert data item before the node at POS, unless INSERT-AFTER is
set."
 (lister-insert-list ewoc pos (list data) level insert-after))

(defalias 'lister-insert-at 'lister-insert)

(defun lister-add (ewoc data &optional level)
  "In EWOC, add DATA as printed item to the end of the list.
Optionally set its LEVEL explicitly, else it will inherit the
level of the previous last item."
  (lister-insert-list ewoc :last (list data) level t))

(defun lister-add-list (ewoc l &optional level)
  "In EWOC, add list L as printed items to the end of the list.
Optionally set their LEVEL explicitly, else they will inherit the
level of the previous last item."
  (lister-insert-list ewoc :last l level t))

(defun lister-replace-list (ewoc l beg end &optional level)
  "In EWOC, insert list L replacing the list from BEG to END.
BEG and END can be a node, a position symbol or an index value.
Optionally indent the new items according to LEVEL."
  (let (insert-at)
    (lister-with-region ewoc beg end
      (setq insert-at (ewoc-next ewoc end))
      (lister-delete-list ewoc beg end))
    (lister-insert-list ewoc (or insert-at :last)
                     l level (null insert-at))))

(defun lister-set-list (ewoc l)
  "Insert L as current list in EWOC, replacing any previous content.
Nested lists will be inserted with nested indentation and can be
retreived with `lister-get-list'.

Note that in some cases, `lister-get-list' will not return the exact
list inserted.  Inserting the list `(A (B) (C))' inserts both
sublists B and C with the same indentation level.  In
consequence, `lister-get-list' returns `(A (B C))' with only one
sublist.  In that case, there is no way to tell that B and C once
belonged to different lists."
  (lister-delete-all ewoc)
  (lister--walk-insert ewoc l 0 nil))

;; * Moving Functions (next, prev)

(cl-defun lister-next-matching (ewoc pos pred)
  "In EWOC, find next match for PRED starting from POS.
PRED is checked against the node's data.  Begin searching from
POS, which is a position understood by `lister--parse-position'.
Return the node found or nil."
  (let* ((node (lister--parse-position ewoc pos)))
    (lister--next-node-matching ewoc node
                             (lambda (n) (funcall pred (lister--item-data (ewoc-data n)))))))

(defun lister-next-visible-matching (ewoc pos pred)
  "In EWOC, moving from POS, find the next visible match for PRED.
PRED is checked against the node's data.  Begin searching from
POS, which is a position understood by `lister--parse-position'.
Return the node found or nil."
  (lister-next-matching ewoc pos
                     ;; we actually compose functions, there should be
                     ;; a generic function for that
                     (lambda (n) (and (lister-node-visible-p n)
                                      (funcall pred (lister--item-data (ewoc-data n)))))))

(cl-defun lister-prev-matching (ewoc pos pred)
  "Moving from POS via MOVE-FN, find the prev node in EWOC matching PRED.
PRED is checked against the node's data.  Begin searching
backwards from POS, which is a position understood by
`lister--parse-position'.  Return the node found or nil."
  (let* ((node (lister--parse-position ewoc pos)))
    (lister--next-node-matching ewoc node
                             (lambda (n) (funcall pred (lister--item-data (ewoc-data n))))
                             #'ewoc-prev)))

(defun lister-prev-visible-matching (ewoc pos pred)
  "Moving from POS, find the prev visible node in EWOC matching PRED.
PRED is checked against the node's data.  Begin searching
backwards from POS, which is a position understood by
`lister--parse-position'.  Return the node found or nil."
  (lister-prev-matching ewoc pos
                     ;; we actually compose functions, there should be
                     ;; a generic function for that
                     (lambda (n) (and (lister-node-visible-p n)
                                      (funcall pred (lister--item-data (ewoc-data n)))))))

;; * Get the data list

(defun lister-get-list (ewoc &optional beg end start-level pred-fn)
  "Return the data fields of EWOC as a list.
Collect the data of all nodes unless BEG and END set a specific
limit.  BEG and END can be any position understood by
`lister--parse-position'.

If PRED-FN is set, restrict to matching nodes.  Note that the
predicate here is checking against the whole ewoc node, not the
item or the item's data!

The result will always start with the indentation level 0, so
sublists will be returned as nested lists, even if BEG and END
coincide with the sublist boundaries.  In these cases, to get
sublists as flat lists, set START-LEVEL to the sublist's
indentation level."
  (lister-with-region ewoc beg end
    ;; make sure begin and end match pred-fn:
    (when pred-fn
      (setq beg (lister--next-or-this-node-matching ewoc beg pred-fn #'ewoc-next))
      (setq end (lister--next-or-this-node-matching ewoc end pred-fn #'ewoc-prev)))
    ;; We traverse the list recursively using 'node' as a global
    ;; pointer to the current item so that nested 'inner' functions
    ;; can move forward that global node which is also used by the
    ;; 'outer' function to which it returns.
    (let ((node beg))
      (cl-labels ((walk (ewoc acc prev-level)
                              (let (level)
                                (while (and node
                                            (>= (setq level (lister-node-get-level node))
                                                prev-level))
                                  (if (> level prev-level)
                                      (push (walk ewoc nil (1+ prev-level)) acc)
                                    (when (or (not pred-fn)
                                              (funcall pred-fn node))
                                      (push (lister--item-data (ewoc-data node)) acc))
                                    (setq node (unless (eq node end)
                                                 (ewoc-next ewoc node)))))
                                (nreverse acc))))
        ;;
        (walk ewoc nil (or start-level 0))))))

(defun lister-get-visible-list (ewoc &optional beg end start-level)
  "Like `lister-get-list', but only consider visible items.
Collect the data of all visible nodes in EWOC.  Nodes or
positions BEG and END set a specific limit.  Use START-LEVEL to
set an initial indentation level for the first item."
  (lister-get-list ewoc beg end (or start-level 0) #'lister-node-visible-p))

;;; * Sublist handling

;; All sublist handling applies to the complete, unfiltered EWOC.

(defun lister--locate-sublist (ewoc pos)
  "Return first and last node in EWOC with the same level as POS."
  (when-let ((node (lister--parse-position ewoc pos)))
    (let* ((item (ewoc-data node))
           (ref-level (or (lister--item-level item) 0))
           (pred-fn   (lambda (n)
                        (< (or (lister--item-level (ewoc-data n)) 0)
                           ref-level)))
           ;; find upper and lower non-sublist boundaries:
           (upper (lister--next-node-matching ewoc node pred-fn #'ewoc-prev))
           (lower (lister--next-node-matching ewoc node pred-fn #'ewoc-next))
           ;; we want the first and last item of the sublist itself:
           (upper (when upper (ewoc-next ewoc upper)))
           (lower (when lower (ewoc-prev ewoc lower)))
           ;; if there was nothing, it is the whole list:
           (upper (or upper (ewoc-nth ewoc 0)))
           (lower (or lower (ewoc-nth ewoc -1))))
      `(,upper ,lower))))

(defmacro lister-with-sublist-at (ewoc pos beg end &rest body)
  "Execute BODY with BEG and END bound to the sublist at POS.
If there is no sublist, do not execute BODY and return nil.

POS can be any value understood by `lister--parse-position'.  BEG
and END have to be symbol names; they are bound to the upper and
lower limit of the sublist at POS.  EWOC is a lister ewoc object."
  (declare (indent 4) (debug (sexp sexp symbolp symbolp body)))
  (unless (and (symbolp beg) (not (keywordp beg)))
    (signal 'wrong-type-argument (list 'symbolp beg)))
  (unless (and (symbolp end) (not (keywordp end)))
    (signal 'wrong-type-argument (list 'symbolp end)))
  (let ((boundaries-var (make-symbol "boundaries")))
    `(let* ((,boundaries-var (lister--locate-sublist ,ewoc ,pos))
            (,beg       (car ,boundaries-var))
            (,end       (cadr ,boundaries-var)))
       (when (and ,beg ,end)
         ,@body))))

(defmacro lister-with-sublist-below (ewoc pos beg end &rest body)
  "Executy BODY with BEG and END bound to the sublist below POS.
If there is no sublist, do not execute BODY and return nil.

POS can be any value understood by `lister--parse-position'.  BEG
and END have to be symbol names; they are bound to the upper and
lower limit of the sublist at POS.  EWOC is a lister ewoc object."
  (declare (indent 4) (debug (sexp sexp symbolp symbolp body)))
  (unless (and (symbolp beg) (not (keywordp beg)))
    (signal 'wrong-type-argument (list 'symbolp beg)))
  (unless (and (symbolp end) (not (keywordp end)))
    (signal 'wrong-type-argument (list 'symbolp end)))
  (let ((node-sym (make-symbol "--node--")))
    `(when-let* ((,node-sym (lister--parse-position ,ewoc ,pos)))
       (when (lister-sublist-below-p ewoc ,node-sym)
         (lister-with-sublist-at ewoc (ewoc-next ewoc ,node-sym)
                              ,beg ,end
           ,@body)))))

(defun lister-sublist-below-p (ewoc pos)
  "Check if in EWOC, there is an indented list below POS.
POS can be either an ewoc node, an index position, or one of the
symbols `:first', `:last', `:point', `:next' or `:prev'."
  (let* ((node (lister--parse-position ewoc pos))
         (next (ewoc-next ewoc node)))
    (when next
      (< (lister-node-get-level node)
         (lister-node-get-level next)))))

(defun lister-insert-sublist-below (ewoc pos l)
  "In EWOC, insert L as an indented list below POS."
  (lister-insert-list ewoc pos l 999 t))

(defun lister-delete-sublist-at (ewoc pos)
  "In EWOC, delete the sublist at POS."
  (lister-with-sublist-at ewoc pos first last
    (lister-delete-list ewoc first last)))

(defun lister-delete-sublist-below (ewoc pos)
  "In EWOC, delete the sublist below POS."
  (lister-with-sublist-below ewoc pos beg end
    (lister-delete-list ewoc beg end)))

(defun lister-replace-sublist-at (ewoc pos l)
  "In EWOC, replace sublist at POS with L."
  (lister-with-sublist-at ewoc pos beg end
    (let ((level (lister-node-get-level beg)))
      (lister-replace-list ewoc l beg end level))))

(defun lister-replace-sublist-below (ewoc pos l)
  "In EWOC, replace sublist below POS with L."
  (lister-with-sublist-below ewoc pos beg end
    (let ((level (lister-node-get-level beg)))
      (lister-replace-list ewoc l beg end level))))

(defun lister-mark-unmark-sublist-at (ewoc pos state)
  "In EWOC, mark or unmark the sublist at POS.
Use boolean STATE t to set the node as 'marked', else nil."
  (lister-with-sublist-at ewoc pos beg end
    (lister-mark-unmark-list ewoc beg end state)))

(defun lister-mark-unmark-sublist-below (ewoc pos state)
  "In EWOC, mark or unmark the sublist below POS.
Use boolean STATE t set the node as 'marked', else nil."
  (lister-with-sublist-below ewoc pos beg end
    (lister-mark-unmark-list ewoc beg end state)))

(defun lister-get-sublist-at (ewoc pos)
  "In EWOC, return the data of the sublist at POS as a list.
If no list is found, return nil."
  (lister-with-sublist-at ewoc pos beg end
    (let ((start-level (lister-node-get-level beg)))
      (lister-get-list ewoc beg end start-level))))

(defun lister-get-sublist-below (ewoc pos)
  "In EWOC, return the sublist below POS."
  (lister-with-sublist-below ewoc pos beg end
    (let ((start-level (lister-node-get-level (ewoc-next ewoc beg))))
      (lister-get-list ewoc beg end start-level))))

;;; * Sorting (or, more abstract, reordering)

(defun lister--wrap-list (l)
  "Wrap nested list L in a list, with sub-lists as its cdr."
  (declare (pure t) (side-effect-free t))
  (let (acc (walk l))
    (while
        (let ((current (car walk))
              (next    (cadr walk)))
          (unless (consp current)
            (push (cons current (when (consp next)
                                  (lister--wrap-list next)))
                  acc))
          (setq walk (cdr walk))))
    (nreverse acc)))

(defun lister--reorder-wrapped-list (wrapped-l fn)
  "Reorder WRAPPED-L using FN and return result as a plain list.
WRAPPED-L is a wrapped list as returned by `lister--wrap-list'.
Return WRAPPED-L as an unwrapped (!) list in the new order
determined by FN.

A 'wrapped' list consists of pairs of CAR and CDR, where each car
contains the list item, and the cdr an associated sublist (or
nil).

FN has to reorder the elements of WRAPPED-L according to the car
of each element, but to leave the wrapped pairs themselves
untouched.  For a function that normally uses predicates on plain
lists, such as sorting functions, this can be done by filtering
the predicate argument with `car'.  Functions that work on plain
lists without inspecting their contents, such as `reverse', work
out of the box.

Example:
\(let* \(\(l   \(lister--wrap-list '\(\"b\" \"a\" \(\"bb\" \"ba\"\)\)\)\)
       \(fn  (apply-partially #'seq-sort-by #'car #'string<\)\)\)
  \(lister--reorder-wrapped-list l fn\)\)

 => \(\"a\" \(\"ba\" \"bb\"\) \"b\"\)"
  (declare (pure t) (side-effect-free t))
  (let (acc (tail  (funcall fn wrapped-l)))
    ;; test at the beginning to ensure that tail is not already empty
    (while tail
      (let ((item    (caar tail))
            (sublist (cdar tail)))
        (push item acc)
        (when (consp sublist)
          (push (lister--reorder-wrapped-list sublist fn) acc))
        (setq tail (cdr tail))))
    (nreverse acc)))

(defun lister--reorder-list (ewoc fn &optional beg end)
  "In EWOC, reorder all items from BEG to END using FN.
BEG and END are nodes or positions understood by
`lister--parse-position'.  If BEG or END are nil, use the beginning
or the end of the list as boundaries; that is, reorder the
complete list.

Note that FN has to reorder a wrapped list and must not undo the
wrapping.  See `lister--reorder-wrapped-list' for an example."
  (lister-with-region ewoc beg end
    (let* ((level        (lister-node-get-level beg))
           (wrapped-list (lister--wrap-list (lister-get-list ewoc beg end level)))
           (new-list     (lister--reorder-wrapped-list wrapped-list fn)))
      (lister-replace-list ewoc new-list beg end level))))

(defun lister-reverse-list (ewoc &optional beg end)
  "Reverse the list in EWOC, preserving sublist associatios.
Use BEG and END to specify the first and the last item of the
list to be reversed."
  (lister--reorder-list ewoc #'reverse beg end))

(defun lister-sort-list (ewoc pred &optional beg end)
  "In EWOC, sort the list and sublists using PRED.
Use BEG and END to specify the first and the last item of the
list to be reversed."
  (lister--reorder-list ewoc (apply-partially #'seq-sort-by #'car pred) beg end))

(defun lister-sort-sublist-at (ewoc pos pred)
  "In EWOC, sort the sublist at POS using PRED."
  (lister-with-sublist-at ewoc pos beg end
    (lister-sort-list ewoc pred beg end)))

(defun lister-sort-sublist-below (ewoc pos pred)
  "In EWOC, sort the sublist below POS using PRED."
  (lister-with-sublist-below ewoc pos beg end
    (lister-sort-list ewoc pred beg end)))

;;; * Filtering

(defun lister-filter-active-p (ewoc)
  "Return non-nil if filter in EWOC is active."
  (buffer-local-value 'lister-local-filter (ewoc-buffer ewoc)))

(defun lister-set-filter (ewoc pred)
  "Set PRED as a display filter in EWOC.
All items whose data matches PRED will be hidden from view.  The
PRED nil effectively removes any existing filter."
  (with-current-buffer (ewoc-buffer ewoc)
    (setq-local lister-local-filter pred)
    (lister-dolist (ewoc data :first :last node)
      (lister--invisibilize-item (ewoc-data node)
                              (and pred (funcall pred data))))))

;;; * Set up buffer for printing:
;;;
;;;###autoload
(defun lister-setup (buf-or-name mapper &optional header footer)
  "Set up buffer BUF-OR-NAME for lister lists.  Return an ewoc object.
If BUF-OR-NAME is a buffer object, erase this buffer's content.
Else create a new buffer with the name BUF-OR-NAME.  You can
access this buffer with (ewoc-buffer).

Store MAPPER as a buffer local variable in BUF.

Optionally pass a HEADER or FOOTER string, or lists of strings."
  (with-current-buffer (get-buffer-create buf-or-name)
    ;; prepare buffer:
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (propertize " "
                          'cursor-intangible t
                          'front-sticky t
                          'field t))
      (goto-char (point-min)))
    (read-only-mode +1)
    (cursor-intangible-mode +1)
    (setq-local lister-local-mapper mapper)
    ;; create ewoc:
    (let ((ewoc (ewoc-create #'lister--ewoc-printer nil nil t)))
      ;; set separate pprinter for header and footer:
      (setf (ewoc--hf-pp ewoc) #'lister--insert-as-hf)
      (ewoc-set-hf ewoc header footer)
      ewoc)))

(provide 'lister)
;;; lister.el ends here
