
Quickstart

    (require 'list-utils)

    (list-utils-flatten '(1 2 (3 4 (5 6 7))))
    ;; '(1 2 3 4 5 6 7)

    (list-utils-depth '(1 2 (3 4 (5 6 7))))
    ;; 3

    (let ((cyclic-list '(1 2 3 4 5 6 7)))
      (nconc cyclic-list (cdr cyclic-list))
      (list-utils-make-linear-inplace cyclic-list))
    ;; '(1 2 3 4 5 6 7)

    (list-utils-cyclic-p '(1 2 3))
    ;; nil

    (list-utils-plist-del '(:one 1 :two 2 :three 3) :two)
    ;; '(:one 1 :three 3)

Explanation

List-utils is a collection of functions for list manipulation.
This library has no user-level interface; it is only useful
for programming in Emacs Lisp.

Notable functionality includes

    * `list-utils-flatten', a robust list-flattener which handles
      cyclic lists, non-nil-terminated lists, and preserves nils
      when they are found as list elements.

    * `tconc', a simple data structure for efficiently appending
      to a list

The following functions are provided:

    `make-tconc'
    `tconc-p'
    `tconc-list'
    `tconc'
    `list-utils-cons-cell-p'
    `list-utils-cyclic-length'
    `list-utils-improper-p'
    `list-utils-make-proper-copy'
    `list-utils-make-proper-inplace'
    `list-utils-make-improper-copy'
    `list-utils-make-improper-inplace'
    `list-utils-linear-p'
    `list-utils-linear-subseq'
    `list-utils-cyclic-p'
    `list-utils-cyclic-subseq'
    `list-utils-make-linear-copy'
    `list-utils-make-linear-inplace'
    `list-utils-safe-length'
    `list-utils-safe-equal'
    `list-utils-depth'
    `list-utils-flat-length'
    `list-utils-flatten'
    `list-utils-alist-or-flat-length'
    `list-utils-alist-flatten'
    `list-utils-insert-before'
    `list-utils-insert-after'
    `list-utils-insert-before-pos'
    `list-utils-insert-after-pos'
    `list-utils-and'
    `list-utils-not'
    `list-utils-xor'
    `list-utils-uniq'
    `list-utils-dupes'
    `list-utils-singlets'
    `list-utils-partition-dupes'
    `list-utils-plist-reverse'
    `list-utils-plist-del'

To use list-utils, place the list-utils.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'list-utils)

Notes

    This library includes an implementation of the classic Lisp
    `tconc' which is outside the "list-utils-" namespace.

Compatibility and Requirements

    No external dependencies

Bugs

TODO

    @@@ spin out hash-table tests into separate library

    test cyclic inputs to all
    test improper inputs to all
    test single-element lists as inputs to all
    test cyclic single-element lists as inputs to all

    should list-utils-make-improper-inplace accept nil as a special case?

    could do -copy/-inplace variants for more functions, consider doing
    so for flatten

    list* returns a non-list on single elt, our function throws an error

; License

Simplified BSD License:

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

  1. Redistributions of source code must retain the above
     copyright notice, this list of conditions and the following
     disclaimer.

  2. Redistributions in binary form must reproduce the above
     copyright notice, this list of conditions and the following
     disclaimer in the documentation and/or other materials
     provided with the distribution.

This software is provided by Roland Walker "AS IS" and any express
or implied warranties, including, but not limited to, the implied
warranties of merchantability and fitness for a particular
purpose are disclaimed.  In no event shall Roland Walker or
contributors be liable for any direct, indirect, incidental,
special, exemplary, or consequential damages (including, but not
limited to, procurement of substitute goods or services; loss of
use, data, or profits; or business interruption) however caused
and on any theory of liability, whether in contract, strict
liability, or tort (including negligence or otherwise) arising in
any way out of the use of this software, even if advised of the
possibility of such damage.

The views and conclusions contained in the software and
documentation are those of the authors and should not be
interpreted as representing official policies, either expressed
or implied, of Roland Walker.
