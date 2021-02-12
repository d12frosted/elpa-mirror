
Quickstart

    (require 'simpleclip)

    (simpleclip-mode 1)

    ;; Press super-c to copy without affecting the kill ring.
    ;; Press super-x or super-v to cut or paste.
    ;; On OS X, use ⌘-c, ⌘-v, ⌘-x.

Explanation

By default, Emacs orchestrates a subtle interaction between the
internal kill ring and the external system clipboard.

`simpleclip-mode' radically simplifies clipboard handling: the
system clipboard and the Emacs kill ring are made completely
independent, and never influence each other.

`simpleclip-mode' also enables support for accessing the system
clipboard from a TTY where possible.  You will likely need to
set up custom keybindings if you want to take advantage of that.

To use simpleclip, place the simpleclip.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'simpleclip)
    (simpleclip-mode 1)

Keybindings

Turning on `simpleclip-mode' activates clipboard-oriented key
bindings which are modifiable in customize.

The default bindings override keystrokes which may be bound as
alternatives for kill/yank commands on your system.  "Traditional"
kill/yank keys (control-k, control-y, meta-y) are unaffected.

The default keybindings are

             super-c   simpleclip-copy
             super-x   simpleclip-cut
             super-v   simpleclip-paste

    control-<insert>   simpleclip-copy
      shift-<delete>   simpleclip-cut
      shift-<insert>   simpleclip-paste

The "super" keybindings are friendly for OS X.  The "insert"/"delete"
keybindings are better suited for Unix and MS Windows.

See Also

    M-x customize-group RET simpleclip RET

Notes

`simpleclip-mode' does not affect `x-select-enable-primary' or
`select-enable-primary'.

Access to the system clipboard from a TTY is provided for those
cases where a literal paste is needed -- for example, where
autopair interferes with pasted input which is interpreted as
keystrokes.  If you are already happy with the copy/paste provided
by your terminal emulator, then you don't need to set up
simpleclip's TTY support.

The following functions may be useful to call from Lisp:

    `simpleclip-get-contents'
    `simpleclip-set-contents'

Compatibility and Requirements

    No external dependencies

    Tested on OS X, X11, and MS Windows

Bugs

    Assumes that transient-mark-mode is on.

    Menu items under Edit are rebound successfully, but the visible
    menu text does not change.  cua-mode does this correctly --
    because of remap?  because of emulation-mode-map-alists?

    Key bindings do not work out-of-the-box with Aquamacs.

TODO

    TTY-friendly key bindings.

    Keep kill-ring commands in Edit menu under modified names.

    Support non-string data types.

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
