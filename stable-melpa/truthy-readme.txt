
Quickstart

    (require 'truthy)

    (truthy "")                   ; nil
    (truthy '[])                  ; nil
    (truthy 0)                    ; nil
    (truthy (lambda ()))          ; nil
    (truthy (make-sparse-keymap)) ; nil
    (truthy 1)                    ; 1
    (truthy '(a b c))             ; '(a b c)
    (truthy '(nil nil nil))       ; nil
    (truthy '([] "" 0))           ; nil

    (truthy-s '([] "" 0))         ; '([] "" 0)         ; shallow test

    (truthy-l '(nil nil nil))     ; '(nil nil nil)     ; lengthwise test

Explanation

This library has no user-level interface; it is only useful
for programming in Emacs Lisp.  Three functions are provided:

    `truthy'
    `truthy-s'
    `truthy-l'

Truthy provides an alternative measure of the "truthiness" of a
value.  Whereas Lisp considers any non-nil value to be "true" when
evaluating a Boolean condition, `truthy' considers a value to be
"truthy" if it has *content*.  If the value is a string or buffer,
it must have non-zero length.  If a number, it must be non-zero.
If a hash, it must have keys.  If a window, it must be live.  See
the docstring to `truthy' for more details.

`truthy' always returns its argument on success.

`truthy-s' is the shallow version of `truthy'.  It does not recurse
into sequences, but returns success if any element of a sequence is
non-nil.

`truthy-l' is the "lengthwise" version of `truthy'.  It does not
recurse into sequences, but returns success if the argument has
length, considering only the variable portion of a data type.

To use truthy, place the truthy.el library somewhere Emacs can find
it, and add the following to your ~/.emacs file:

    (require 'truthy)

Notes

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.3 and lower : no

    Uses if present: list-utils.el

Bugs

    truthy-l is fairly meaningless on structs

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
