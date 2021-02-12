
Quickstart

    (require 'font-utils)

    (font-utils-exists-p "Courier")

Explanation

Font-utils is a collection of functions for working with fonts.
This library has no user-level interface; it is only useful
for programming in Emacs Lisp.

The following functions are provided, most of which deal with
font names rather than font objects:

    `font-utils-exists-p'
    `font-utils-first-existing-font'
    `font-utils-is-qualified-variant'
    `font-utils-lenient-name-equal'
    `font-utils-list-names'
    `font-utils-name-from-xlfd'
    `font-utils-normalize-name'
    `font-utils-parse-name'
    `font-utils-read-name'

The most generally useful of these is `font-utils-exists-p', which
tests whether a font matching the given name is currently available
for use.

To use font-utils, place the font-utils.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'font-utils)

See Also

    M-x customize-group RET font-utils RET

Notes

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.3 and lower : no

    Uses if present: persistent-soft.el (Recommended)

Bugs

    Behavior/echo messages are not sane when font-utils-use-memory-cache
    is nil, or pcache is not available.

    Checking for font availability is slow on most systems.
    Workaround: where supported, font information will be cached
    to disk.  See customize for more.

    font-utils-exists-p only supports two styles of font
    name.  This page

        http://www.gnu.org/software/emacs/manual/html_node/emacs/Fonts.html#Fonts

    describes four styles of font name.

TODO

    Better support for disabling caching.

    Possibly return a font object instead of font-info vector
    from font-utils-exists-p.

    Test whether (find-font (font-spec :name "Name")) is faster
    than font-info.

    font-utils-create-fuzzy-matches is not exhaustive enough
    to catch many typos.

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
