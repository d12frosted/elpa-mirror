This code provides a minor mode to enable the some of picture-mode
commands documented in the Emacs manual in order to treat the
screen as a semi-infinite quarter-plane, without changing the
buffer's major mode.

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