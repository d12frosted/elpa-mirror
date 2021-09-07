
Quickstart

    (require 'nav-flash)

    (nav-flash-show)

Explanation

Nav-flash temporarily highlights the line containing the point,
which is sometimes useful for orientation after a navigation
command.

To use nav-flash, place the nav-flash.el library somewhere Emacs
can find it, and add the following to your ~/.emacs file:

    (require 'nav-flash)

There is no user-level interface for this library; it is only used
by other Lisp libraries.  However, you might find it useful to call
`nav-flash-show' in your ~/.emacs file.  For example, the following
hook causes a flash to appear after navigating via imenu:

    (add-hook 'imenu-after-jump-hook 'nav-flash-show nil t)

See Also

    M-x customize-group RET nav-flash RET
    M-x customize-group RET pulse RET

Notes

    This library reuses a timer and overlay defined in compile.el,
    but should not affect the normal use of compile.el / `next-error'.

    Pulse.el provides similar functionality and is included with
    Emacs.  This library can use pulse.el, but does not do so by
    default, because pulse.el uses `sit-for', breaking this type
    of construction:

        (nav-flash-show)
        (with-temp-message "message here"
           (sit-for 2))

    When using an overlay and timer for cleanup (as nav-flash does
    by default) the flash and message appear simultaneously.

    Nav-flash.el is also simpler than pulse.el.

Compatibility and Requirements

    GNU Emacs version 25.1-devel     : not tested
    GNU Emacs version 24.5           : not tested
    GNU Emacs version 24.4           : yes
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    No external dependencies

Bugs

    No known bugs.

TODO

    Check pulse period on other platforms.

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
