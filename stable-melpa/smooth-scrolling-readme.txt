To interactively toggle the mode on / off:

    M-x smooth-scrolling-mode

To make the mode permanent, put this in your .emacs:

    (require 'smooth-scrolling)
    (smooth-scrolling-mode 1)

This package offers a global minor mode which make emacs scroll
smoothly.  It keeps the point away from the top and bottom of the
current buffer's window in order to keep lines of context around
the point visible as much as possible, whilst minimising the
frequency of sudden scroll jumps which are visually confusing.

This is a nice alternative to all the native `scroll-*` custom
variables, which unfortunately cannot provide this functionality
perfectly.  For example, when using the built-in variables, clicking
with the mouse in the margin will immediately scroll the window to
maintain the margin, so the text that you clicked on will no longer be
under the mouse.  This can be disorienting.  In contrast, this mode
will not do any scrolling until you actually move up or down a line.

Also, the built-in margin code does not interact well with small
windows.  If the margin is more than half the window height, you get
some weird behavior, because the point is always hitting both the top
and bottom margins.  This package auto-adjusts the margin in each
buffer to never exceed half the window height, so the top and bottom
margins never overlap.

See the README.md for more details.
