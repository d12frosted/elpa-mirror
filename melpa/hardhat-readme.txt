
Quickstart

    (require 'hardhat)

    (global-hardhat-mode 1)

    ;; now you are protected from editing:
    ;;
    ;;     .git/index
    ;;     ~/.emacs.d/elpa/hardhat-0.1.0/hardhat.el
    ;;     ~/.emacs~
    ;;
    ;; and many others

Explanation

A recent unwholesome trend is for package managers to install files
in locations such as ~/.cabal/, ~/.rvm/, or ~/.emacs.d/elpa/.  It
is rarely meant for such files to be edited; doing so can cause
data loss in some circumstances.

In addition, many user-writable files created in the course of
ordinary work should never be altered by a text editor, eg the
database stored in a .git directory.

Hardhat.el provides an extra layer of protection in your work.  If
you visit a file which looks unsafe to edit, Emacs will make the
buffer read-only -- even when the underlying file is writable.

The read-only protection can be turned off for a buffer by the
usual methods, or by toggling off buffer-local hardhat-mode via
the lighter menu or

    M-x hardhat-mode RET

If a buffer is not visiting a file, `hardhat-mode' has no effect.
If the visited file is not writable by the user, `hardhat-mode'
has no effect.

To use hardhat, place the hardhat.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'hardhat)
    (global-hardhat-mode 1)

To inquire as to why hardhat has set or unset protection in
a buffer, the following interactive command is provided

    `hardhat-status'

but not bound to any key.

See Also

    M-x customize-group RET hardhat RET

Notes

    `hardhat-mode' takes no action until the user attempts an
    interactive command in a buffer.  This is (out of an abundance
    of caution) for compatibility: an Emacs Lisp library may freely
    open and write to a file protected by `hardhat-mode', so long as
    it is done programatically.

    For any of the options settable in customize, rules making
    buffers "editable" override rules making buffers "protected".

    A Boolean file-local variable `hardhat-protect' is provided.
    When `hardhat-protect' is set to either t or nil, no other
    rules are consulted.

    Regular-expression matches are case-insensitive.  A case-
    sensitive test can be implemented by adding custom function
    to eg `hardhat-buffer-protected-functions'.

Compatibility and Requirements

    GNU Emacs version 25.1-devel     : not tested
    GNU Emacs version 24.5           : not tested
    GNU Emacs version 24.4           : yes
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    Uses if present: ignoramus.el

Prior art

    do-not-edit.el
    http://user42.tuxfamily.org/do-not-edit/index.html
    Kevin Ryde <user42@zip.com.au>

Bugs

    More exceptions are certainly needed in `hardhat-fullpath-editable-regexps'

    Because Emacs can wedge if `file-truename' is called on a
    remote file (eg when using TRAMP), some filename tests used in
    hardhat are not precisely equivalent between local and remote
    files.  You can change this behavior by setting
    `hardhat-use-unsafe-remote-truename' via customize.  A better
    solution is to set `find-file-visit-truename' globally.

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
