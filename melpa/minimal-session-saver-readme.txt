
Quickstart

    (require 'minimal-session-saver)

    (minimal-session-saver-install-aliases)

    M-x mss-store RET

    ;; quit and restart Emacs

    M-x mss-load RET

Explanation

The only information stored by this library is a list of visited
files.  Not window configuration, nor point position.

Giving a universal prefix argument to any of the interactive
session-management commands causes a prompt for the session-state
file location, allowing minimal-session-saver to be used as a
(very) minimal project manager.

When frame-bufs.el is present, the session associated with a
particular frame can be stored and recovered.

To use minimal-session-saver, place the minimal-session-saver.el
library somewhere Emacs can find it, and add the following to your
~/.emacs file:

    (require 'minimal-session-saver)

Several interactive commands are provided to manage sessions:

    minimal-session-saver-store
    minimal-session-saver-load
    minimal-session-saver-store-frame         ; requires frame-bufs.el
    minimal-session-saver-load-frame          ; requires frame-bufs.el
    minimal-session-saver-add-buffer
    minimal-session-saver-remove-buffer
    minimal-session-saver-mark-stored-buffers

without keybindings.

An additional command

    minimal-session-saver-install-aliases

installs shorter command aliases for the above, and can
be run at autoload-time through a setting in customize.

See Also

    M-x customize-group RET minimal-session-saver RET

Notes

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    Uses if present: frame-bufs.el

Bugs

TODO

    Store multiple sets/frames in same data file and
    prompt for choice on load?

    Prompt to save all files before running -store

    don't count already marked buffers in buff-menu function

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
