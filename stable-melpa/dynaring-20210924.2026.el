;;; dynaring.el --- A dynamically sized ring structure -*- lexical-binding: t -*-

;; Author: Mike Mattie <codermattie@gmail.com>
;;         Sid Kasivajhula <sid@countvajhula.com>
;; Maintainer: Sid Kasivajhula <sid@countvajhula.com>
;; URL: https://github.com/countvajhula/dynaring
;; Package-Version: 20210924.2026
;; Package-Commit: 76142cf100d9e611024638a761e62bd82af156cd
;; Created: 2009-4-16
;; Version: 0.3
;; Package-Requires: ((emacs "25.1"))

;; This file is NOT a part of Gnu Emacs.

;; This work is "part of the world."  You are free to do whatever you
;; like with it and it isn't owned by anybody, not even the
;; creators.  Attribution would be appreciated and is a valuable
;; contribution in itself, but it is not strictly necessary nor
;; required.  If you'd like to learn more about this way of doing
;; things and how it could lead to a peaceful, efficient, and creative
;; world, and how you can help, visit https://drym.org.
;;
;; This paradigm transcends traditional legal and economic systems, but
;; for the purposes of any such systems within which you may need to
;; operate:
;;
;; This is free and unencumbered software released into the public domain.
;; The authors relinquish any copyright claims on this work.

;;; Commentary:

;; A dynamically sized ring structure.

;;; Code:

(defconst dynaring-version "0.3")

(require 'seq)

;;
;; ring structure
;;

(defun dynaring-make ()
  "Return a new dynamic ring stucture.

A ring structure is a cons cell where the car is the current head
element of the ring, and the cdr is the number of elements in the
ring."
  (cons nil 0))

(defun dynaring-head (ring)
  "Return the head segment of the RING."
  (car ring))

(defun dynaring-set-head (ring new-head)
  "Set the head of the RING to NEW-HEAD."
  (setcar ring new-head))

(defun dynaring-empty-p (ring)
  "Return t if RING has no elements."
  (not (dynaring-head ring)))

(defun dynaring-size (ring)
  "Return the number of elements in RING."
  (cdr ring))

(defun dynaring-set-size (ring new-size)
  "Set the size of RING to NEW-SIZE."
  (setcdr ring new-size))

(defun dynaring-value (ring)
  "Return the value of RING's head segment."
  (let ((head (dynaring-head ring)))
    (when head
      (dynaring-segment-value head))))

(defun dynaring-equal-p (r1 r2)
  "Check if two rings R1 and R2 are equal.

Equality of rings is defined in terms of contained values, structure,
and orientation."
  (equal (dynaring-values r1)
         (dynaring-values r2)))

;;
;; ring segments
;;

(defconst dynaring-linkage 0)
(defconst dynaring-value   1)

(defun dynaring-make-segment (value)
  "Create a new dynamic ring segment containing VALUE.

A segment stores a value within a ring with linkage to the
other segments in the ring.  It is an array.

[linkage,value]

linkage is a cons cell.  The car points to the left segment in
the ring.  The cdr points to the right segment in the ring."
  (let
    ((new-elm (make-vector 2 nil)))
    (aset new-elm dynaring-value value)
    (aset new-elm dynaring-linkage (cons nil nil))
    new-elm))

(defun dynaring-segment-value (segment)
  "Return the value of SEGMENT."
  (aref segment dynaring-value))

(defun dynaring-segment-set-value (segment value)
  "Set the value of SEGMENT to VALUE."
  (aset segment dynaring-value value))

(defun dynaring-segment-linkage (segment)
  "Return the linkage of SEGMENT."
  (aref segment dynaring-linkage))

(defun dynaring-segment-previous (segment)
  "Return the previous SEGMENT in the ring."
  (car (dynaring-segment-linkage segment)))

(defun dynaring-segment-set-previous (segment new-segment)
  "Set the previous SEGMENT in the ring to NEW-SEGMENT."
  (setcar (dynaring-segment-linkage segment) new-segment))

(defun dynaring-segment-next (segment)
  "Return the next SEGMENT in the ring."
  (cdr (dynaring-segment-linkage segment)))

(defun dynaring-segment-set-next (segment new-segment)
  "Set the previous SEGMENT in the ring to NEW-SEGMENT."
  (setcdr (dynaring-segment-linkage segment) new-segment))

;;
;; ring traversal.
;;

(defun dynaring-traverse (ring fn)
  "Walk the elements of RING passing each element to FN.

This performs FN as a side effect and does not modify the ring in any
way, nor does it return a result."
  (let ((head (dynaring-head ring)))
    (when head
      (funcall fn (dynaring-segment-value head))
      (let ((current (dynaring-segment-next head)))
        ;; loop until we return to the head
        (while (and current (not (eq current head)))
          (funcall fn (dynaring-segment-value current))
          (setq current (dynaring-segment-next current)))
        t))))

(defun dynaring-traverse-collect (ring fn)
  "Walk the elements of RING passing each element to FN.

The values of FN for each element are collected into a list and
returned."
  (let ((output nil))
    (dynaring-traverse ring
                       (lambda (element)
                         (push (funcall fn element) output)))
    output))

(defun dynaring-map (ring fn)
  "Derive a new ring by transforming RING under FN.

Walk the elements of RING passing each element to FN, creating a new
ring containing the transformed elements.  This does not modify the
original RING.

`dynaring-transform-map` is a mutating version of this interface."
  (let ((new-ring (dynaring-make)))
    (if (dynaring-empty-p ring)
        new-ring
      (let ((head (dynaring-head ring)))
        (let ((new-head (dynaring-insert new-ring
                                         (funcall fn (dynaring-segment-value head)))))
          (let ((current (dynaring-segment-previous head)))
            (while (not (eq current head))
              (dynaring-insert new-ring
                               (funcall fn (dynaring-segment-value current)))
              (setq current (dynaring-segment-previous current))))
          (dynaring-set-head new-ring new-head)
          new-ring)))))

(defun dynaring-filter (ring predicate)
  "Derive a new ring by filtering RING using PREDICATE.

Walk the elements of RING passing each element to PREDICATE, creating
a new ring containing those elements for which PREDICATE returns a
non-nil result.  This does not modify the original RING.

`dynaring-transform-filter` is a mutating version of this interface."
  (let ((new-ring (dynaring-make)))
    (if (dynaring-empty-p ring)
        new-ring
      (let* ((head (dynaring-head ring))
             (current (dynaring-segment-previous head))
             (current-value (dynaring-segment-value current)))
        (while (not (eq current head))
          ;; go the other way around the ring so that the head
          ;; is the last segment encountered, to avoid having to
          ;; keep track of a potentially changing head
          (when (funcall predicate current-value)
            (dynaring-insert new-ring current-value))
          (setq current (dynaring-segment-previous current))
          (setq current-value (dynaring-segment-value current)))
        ;; check the head
        (when (funcall predicate current-value)
          (let ((new-head (dynaring-insert new-ring current-value)))
            (dynaring-set-head new-ring new-head)))
        new-ring))))

(defun dynaring-transform-map (ring fn)
  "Transform the RING by mapping each of its elements under FN.

This mutates the existing ring.

`dynaring-map` is a functional (non-mutating) version of this
interface."
  (unless (dynaring-empty-p ring)
    (let ((head (dynaring-head ring)))
      (dynaring-segment-set-value head
                                  (funcall fn (dynaring-segment-value head)))
      (let ((current (dynaring-segment-previous head)))
        (while (not (eq current head))
          (dynaring-segment-set-value current
                                      (funcall fn (dynaring-segment-value current)))
          (setq current (dynaring-segment-previous current))))
      (dynaring-set-head ring head)
      t)))

(defun dynaring-transform-filter (ring predicate)
  "Transform RING by filtering its elements using PREDICATE.

This retains only those elements for which PREDICATE returns a non-nil
result.  This mutates the existing RING.

`dynaring-filter` is a functional (non-mutating) version of this
interface."
  (unless (dynaring-empty-p ring)
    (let* ((head (dynaring-head ring))
           (current (dynaring-segment-previous head))
           (current-value (dynaring-segment-value current)))
      (while (not (eq head current))
        ;; go the other way around the ring so that the head
        ;; is the last segment encountered, to avoid having to
        ;; keep track of a potentially changing head
        (let ((previous (dynaring-segment-previous current)))
          (unless (funcall predicate current-value)
            (dynaring-delete-segment ring current))
          (setq current previous)
          (setq current-value (dynaring-segment-value current))))
      ;; check the head
      (unless (funcall predicate current-value)
        (dynaring-delete-segment ring current))
      t)))

(defun dynaring-rotate-until (ring direction fn)
  "Rotate the RING until some condition is met.

DIRECTION specifies which direction to rotate in, and must be one of
two functions: `dynaring-rotate-right` or `dynaring-rotate-left`.

The rotation continues until the FN predicate which evaluates the new
head element of each rotation returns non-nil.

If the predicate does not return non-nil the ring is reset to the head
element it started with."
  (let
    ((start (dynaring-head ring)))

    (catch 'stop

      (when start
        (if (funcall fn (dynaring-value ring))
            (throw 'stop t)
          (when (= (dynaring-size ring) 1)
            (throw 'stop nil)))

        (funcall direction ring)

        ;; when we have moved off the start loop until we return to it.
        (while (not (eq (dynaring-head ring) start))
          (when (funcall fn (dynaring-value ring))
            (throw 'stop t))
          (funcall direction ring))
        nil)) ))

(defun dynaring--find (ring predicate direction)
  "Search RING for an element matching a PREDICATE.

Searches in DIRECTION for the first element that matches PREDICATE.
DIRECTION must be either `dynaring-segment-next` (to search forward)
or `dynaring-segment-previous` (to search backwards).

The ring segment containing the matching element is returned, or nil
if a matching element isn't found."
  (unless (dynaring-empty-p ring)
    (let* ((head (dynaring-head ring))
           (current head))
      (if (funcall predicate (dynaring-segment-value head))
          head
        (let ((current (funcall direction current)))
          (catch 'stop
            (while (not (eq current head))
              (when (funcall predicate (dynaring-segment-value current))
                (throw 'stop current))
              (setq current (funcall direction current)))
            nil))))))

(defun dynaring-find-forwards (ring predicate)
  "Search RING in the forward direction.

Searches for the first element that matches PREDICATE.

The ring segment containing the matching element is returned, or nil
if a matching element isn't found."
  (dynaring--find ring predicate #'dynaring-segment-next))

(defun dynaring-find-backwards (ring predicate)
  "Search RING in the backward direction.

Searches for the first element that matches PREDICATE.

The ring segment containing the matching element is returned, or nil
if a matching element isn't found."
  (dynaring--find ring predicate #'dynaring-segment-previous))

(defun dynaring-contains-p (ring element)
  "Predicate to check whether RING contains ELEMENT."
  (dynaring-find-forwards ring
                          (lambda (elem)
                            (eq elem element))))

;;
;; ring modification functions.
;;

(defun dynaring-destroy (ring)
  "Delete the RING.

The circular linkage of a ring structure makes it doubtful that the
garbage collector will be able to free a ring without calling
`dynaring-destroy`."
  (unless (dynaring-empty-p ring)
    (let
        ((current (dynaring-head ring)))

      ;; Break the ring by terminating the previous element
      (dynaring--free-segment (dynaring-segment-previous current))

      (while (dynaring-segment-next current)
        (let
            ((next (dynaring-segment-next current)))

          ;; delete all the links in the current element
          (dynaring--free-segment current)

          ;; move to the right
          (setq current next)))
      ;; delete the head pointer.
      (dynaring-set-head ring nil)
      (dynaring-set-size ring 0)
      t)))

(defun dynaring--link (previous next)
  "Link PREVIOUS and NEXT to one another."
  (dynaring-segment-set-previous next previous)
  (dynaring-segment-set-next previous next))

(defun dynaring-insert (ring element)
  "Insert ELEMENT into RING.

The head of the ring will be the new ELEMENT."
  (let ((segment (dynaring-make-segment element))
        (ring-size (dynaring-size ring))
        (head (dynaring-head ring)))
    (cond
     ((equal 0 ring-size)
      (dynaring--link segment segment))

     (t
      (let ((previous (dynaring-segment-previous head)))
        (dynaring--link previous segment)
        (dynaring--link segment head))))

    ;; point the head at the new segment
    (dynaring-set-head ring segment)
    ;; update the element count.
    (dynaring-set-size ring (1+ ring-size))

    ;; return the newly inserted segment.
    segment))

(defun dynaring--unlink-segment (segment)
  "Unlink SEGMENT from its neighboring segments.

Unlinks the SEGMENT by relinking its left and right segments to
each other."
  (dynaring--link (dynaring-segment-previous segment)
                  (dynaring-segment-next segment)))

(defun dynaring--free-segment (segment)
  "Nullify links in SEGMENT.

This is an extra precaution to make sure that the garbage collector
reclaims it (e.g. if the segment happens to point to itself)."
  (dynaring-segment-set-next segment nil)
  (dynaring-segment-set-previous segment nil))

(defun dynaring-delete-segment (ring segment)
  "Delete SEGMENT from RING."
  (let
    ((ring-size (dynaring-size ring)))

    (when (> ring-size 0)
      (cond
       ((equal 1 ring-size)
        (dynaring--free-segment (dynaring-head ring))
        (dynaring-set-head ring nil))
       (t
        (dynaring--unlink-segment segment)

        ;; if we deleted the head element set the
        ;; head to the right element.
        (when (eq (dynaring-head ring) segment)
          (dynaring-set-head ring (dynaring-segment-next segment)))
        (dynaring--free-segment segment)))
      (dynaring-set-size ring (1- (dynaring-size ring)))
      t)))

(defun dynaring-delete (ring element)
  "Delete ELEMENT from RING."
  (let ((segment (dynaring-find-forwards ring
                                         (lambda (elem)
                                           (eq elem element)))))
    (when segment
      (dynaring-delete-segment ring segment))))

(defun dynaring-rotate-left (ring)
  "Rotate the RING towards the left.

Rotate the head of ring to the element left of the current head."
  (unless (dynaring-empty-p ring)
    (dynaring-set-head ring
                       (dynaring-segment-previous
                        (dynaring-head ring)))))

(defun dynaring-rotate-right (ring)
  "Rotate the RING towards the RIGHT.

Rotate the head of ring to the element right of the current head."
  (unless (dynaring-empty-p ring)
    (dynaring-set-head ring
                       (dynaring-segment-next
                        (dynaring-head ring)))))

(defun dynaring-break-insert (ring element)
  "Add ELEMENT to the RING or move it to the head if already present.

This performs a simple insertion if the element isn't already in the
ring.  In the case where the element is already in the ring, the
element is removed from its original location and re-inserted at the
head.  Essentially, the ring is \"broken\" and \"recast\" to place the
element at the head.  This can be used to model \"recency.\""
  (dynaring-delete ring element)
  (dynaring-insert ring element))

(defun dynaring-values (ring)
  "A list of all values contained in the RING.

The values are obtained by traversing the ring from the end back
around to the head, so the head will be the last item in the list
rather than the first one.  Aside from that, while the order of the
other elements will remain consistent with a linearization of the ring
structure, it is otherwise arbitrary, since we could go around the
ring in either direction."
  (dynaring-traverse-collect ring #'identity))

(provide 'dynaring)
;;; dynaring.el ends here
