This package provides Quarter Plane mode, a minor mode which
provides Picture mode style editing (treating the screen as a
semi-infinite quarter-plane).  Unlike Picture mode, it is a minor
mode (see the Emacs manual for the documentation of Picture mode).
Type M-x quarter-plane-mode to enable Quarter Plane mode in the
current buffer, and M-x global-quarter-plane-mode to enable it
globally.

In Quarter Plane mode, the commands `right-char', `forward-char',
`previous-line', `next-line', and `mouse-set-point' are rebound to
Quarter Plane commands.

Known issues:

Quarter-Plane mode doesn't work in read-only buffers, where it
can't insert spaces.

The user doesn't really care about the "modifications" of adding
whitespace that's going to be trimmed when he exits quarter-plane
mode or saves, but it's still part of the undo history.

Both of these are due to the disconnect between what the user
really wants--movement of the cursor within the window, regardless
of where the text is--and what the mode can actually do--add dummy
text to give the cursor a place to move to.