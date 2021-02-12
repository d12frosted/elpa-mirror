
Quickstart

    (require 'vector-utils)

    (vector-utils-flatten '[1 2 [3 4 [5 6 7]]])
    ;; '[1 2 3 4 5 6 7]

    (vector-utils-depth '[1 2 [3 4 [5 6 7]]])
    ;; 3

Explanation

Vector-utils is a collection of functions for vector manipulation.
This library has no user-level interface; it is only useful for
programming in Emacs Lisp.

Furthermore (when programming in Emacs Lisp), be aware that the
modification of a vector is not permitted: only vector *elements*
may be changed.  All "modification" operations herein can only
work by making copies, which is not efficient.

The following functions are provided:

    `vector-utils-depth'
    `vector-utils-flatten'
    `vector-utils-insert-before'
    `vector-utils-insert-after'
    `vector-utils-insert-before-pos'
    `vector-utils-insert-after-pos'

To use vector-utils, place the vector-utils.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'vector-utils)

Notes

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes
    GNU Emacs version 21.x and lower : unknown

    No external dependencies

See Also

    Why you should not modify vectors
    http://emacswiki.org/emacs/VectorUsage

Bugs

TODO

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
