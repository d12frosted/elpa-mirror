
Quickstart

    (require 'unicode-enbox)

    (insert "\n" (unicode-enbox "testing"))

Explanation

Unicode-enbox.el has no user-level interface; it is only useful
for programming in Emacs Lisp.

This library provides two functions:

    unicode-enbox
    unicode-enbox-debox

which can be used to add/remove box-drawing characters around
a single- or multi-line string.

To use unicode-enbox, place the unicode-enbox.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'unicode-enbox)

See Also

    M-x customize-group RET unicode-enbox RET

Notes

For good monospaced box-drawing characters, it is recommended to
install the free DejaVu Sans Mono font and use unicode-fonts.el.
If unicode-fonts.el is too heavy for your needs, try adding the
following bit to your ~/.emacs file:

    (set-fontset-font "fontset-default"
                      (cons (decode-char 'ucs #x2500)  (decode-char 'ucs #x257F))
                      '("DejaVu Sans Mono" . "iso10646-1"))


Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.3 and lower : no

    Requires string-utils.el, ucs-utils.el

Bugs

TODO

    Interactive command that works on rectangles.

    Logic in unicode-enbox is not clear, eg where it falls through
    to 'smart.

    Detect lines of full dashes, replace with box chars and
    connectors, then would need more clever deboxing - or just
    store the original string in a property - done?

    Detect acutal width of unicode characters in GUI - char-width
    does not return the right answer.

    Generalize to comment boxes with multi-character drawing
    elements.

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
