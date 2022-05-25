swsw - Simple window switching

swsw (simple window switching) is an Emacs package which provides a minor mode
for switching to windows using IDs assigned to them automatically.

Installation:

From ELPA: (not available yet)

M-x package-install RET swsw RET

From the repository:

Clone the repository:

$ git clone 'https://git.sr.ht/~dsemy/swsw'

Build the package:

$ cd swsw

$ make

Install the package:

M-x package-install-file RET /path/to/clone/swsw-VERSION.tar RET

Usage:

Enable ‘swsw-mode’:

(swsw-mode)

For use-package users:

(use-package swsw
  :config
  (swsw-mode))

When swsw-mode is active:
- A window ID is displayed using a mode line lighter or a display
  function (see ‘swsw-display-function’).
- Window IDs are assigned to all windows on all frames except for
  the minibuffer(by default, see ‘swsw-scope’).

C-x o ID switches focus to the window which corresponds to ID.

C-x o m switches focus to the minibuffer if it's active.

C-x o 0 ID deletes the window which corresponds to ID.

More commands can be added through ‘swsw-command-map’:

(define-key swsw-command-map [?a] #'my-command)

You can customize ‘swsw-mode’ using the customize interface:

M-x customize-group RET swsw RET

For more information see the (swsw) info node.

Copyright:

Copyright © 2020-2022 Daniel Semyonov <daniel@dsemy.com>
Licensed under GPLv3 or later.
