hiddenquote is a kind of word puzzle where you have to read
word definitions (the clues), and put the answer into a grid, using
the provided syllables.  When the grid is complete, you should be able
to read a quote in the highlighted cells.

This word puzzle is known in Argentina as Claringrilla, because they are
published by a national newspaper named "Clarín".

This file contains all the hidden quote puzzle rendering, major mode
and commands.  It also defines a source to retrieve puzzles of
the hidden quote type, created by myself.

Usage:
M-x hiddenquote
Select the source you want to retrieve the puzzle from.
With a prefix argument, the command will prompt for a specific ID number.

Read the clues in the Definitions buffer, and complete each word with
one character per cell to complete the puzzle.  For each work, mark the
syllables it contains as used.
Move around the buffer with the usual movement commands.
Edit each character cell with the usual editing commands.
To mark a syllable as used, click it with the mouse or move point to
it and hit RET.
When the puzzle is complete, you should be able to read the hidden
quote in the highlighted cells.

M-x customize-group RET hiddenquote
to see other customization options.
To see what faces you can customize, type
M-x customize-group RET hiddenquote-faces
M-x describe-keymap RET hiddenquote-mode-map
or
M-x describe-keymap RET hiddenquote-character-map
to see the commands available.

To change the puzzle sources, customize `hiddenquote-sources'.