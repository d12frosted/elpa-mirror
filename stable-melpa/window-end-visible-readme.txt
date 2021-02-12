
Quickstart

    (require 'window-end-visible)

    ;; open a buffer larger than the window

    ;; may return nil
    M-: (pos-visible-in-window-p (window-end)) RET

    ;; always returns t
    M-: (pos-visible-in-window-p (window-end-visible)) RET

Explanation

Window-end-visible.el has no user-level interface, and is only
useful when programming Emacs Lisp.

This library provides the function `window-end-visible', which
works around a limitation of `window-end', at a speed penalty.

The issue this function solves is that the following is not true
as might be expected:

   (pos-visible-in-window-p (window-end))

`window-end-visible' returns the "true" window end: the last
visible position in the window, verified by testing with
`pos-visible-in-window-p'.

The speed penalty of `window-end-visible' over `window-end' varies
depending on your configuration.  For example, tabbar.el makes
calling `pos-visible-in-window-p' quite expensive.

To use window-end-visible, place the window-end-visible.el library
somewhere Emacs can find it, and add the following to your ~/.emacs
file:

    (require 'window-end-visible)

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
