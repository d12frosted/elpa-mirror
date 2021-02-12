The standard library tooltip.el provides the function for displaying
a tooltip at mouse position which allows users to easily show it.
However, locating tooltip at arbitrary buffer position in window
is not easy. This program provides such function to be used by other
frontend programs.

This program is tested on GNU Emacs 22, 23 under X window system and
Emacs 23 for MS-Windows.


Installation:

First, save this file as pos-tip.el and byte-compile in
a directory that is listed in load-path.

Put the following in your .emacs file:

  (require 'pos-tip)

To use the full features of this program on MS-Windows,
put the additional setting in .emacs file:

  (pos-tip-w32-max-width-height)   ; Maximize frame temporarily

or

  (pos-tip-w32-max-width-height t) ; Keep frame maximized


Examples:

We can display a tooltip at the current position by the following:

  (pos-tip-show "foo bar")

If you'd like to specify the tooltip color, use an expression as:

  (pos-tip-show "foo bar" '("white" . "red"))

Here, "white" and "red" are the foreground color and background
color, respectively.
