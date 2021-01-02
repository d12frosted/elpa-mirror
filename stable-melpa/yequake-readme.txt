This package provides configurable, drop-down Emacs frames, similar to drop-down terminal windows
programs, like Yakuake.  Each frame can be customized to display certain buffers in a certain
way, at the desired height, width, and opacity.  The idea is to call the `yequake-toggle' command
from outside Emacs, using emacsclient, by binding a shell command to a global keyboard shortcut
in the desktop environment.  Then, with a single keypress, the desired Emacs frame can be toggled
on and off, showing the desired buffers.

;; Installation

;;; MELPA

If you installed from MELPA, you're done.

;;; Manual

Install these required packages:

+ a

Then put this file in your load-path, and put this in your init file:

(require 'yequake)

;; Usage

Run one of these commands:

`yequake-toggle': Toggle a configured Yequake frame.

This is mainly intended to be called from outside Emacs.  So:

1.  Start an Emacs daemon.
2.  Run in a shell:  emacsclient -n -e "(yekuake-toggle "FRAME-NAME")"

If you bind that shell command to a global keyboard shortcut, you can easily toggle the frame on
and off.

;; Tips

+ You can customize settings in the `yequake' group.

;; Credits

Inspired by Benjamin Slade's `equake' package: <https://gitlab.com/emacsomancer/equake>
