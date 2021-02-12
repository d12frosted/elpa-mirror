
Quickstart

    (require 'buffer-utils)

    (buffer-utils-save-order
      (bury-buffer "*scratch*"))

    ;; buffer order is now restored

Explanation

Buffer-utils.el is a collection of functions for buffer manipulation.

This library exposes very little user-level interface; it is
generally useful only for programming in Emacs Lisp.

To use buffer-utils, place the buffer-utils.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'buffer-utils)

The following functions and macros are provided:

    `buffer-utils-all-in-mode'
    `buffer-utils-all-matching'
    `buffer-utils-bury-and-forget'   ; can be called interactively
    `buffer-utils-first-matching'
    `buffer-utils-huge-p'
    `buffer-utils-in-mode'
    `buffer-utils-most-recent-file-associated'
    `buffer-utils-narrowed-p'
    `buffer-utils-save-order'
    `buffer-utils-set-order'

of which `buffer-utils-save-order' is the most notable.

`buffer-utils-save-order' is a macro, similar to `save-current-buffer',
which saves and restores the order of the buffer list.

Notes

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

   No external dependencies

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
