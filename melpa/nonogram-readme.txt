Nonogram is a player for nonogram puzzles (also known as picross,
griddlers or hanjie).  Fill the grid so that each row and column
matches its clue numbers, revealing a hidden picture.

The whole board, including the clue numbers, is drawn with SVG on a
solid white background so it stays legible under any Emacs theme,
light or dark.

Usage:

  M-x nonogram

This opens a list of the puzzles found in `nonogram-puzzle-directory'
(files in Steven Simpson's .non format).  Move with n and p and press
RET to play the puzzle under point.

If the directory is empty, Nonogram offers to download a set of
puzzles from `nonogram-puzzle-source-url'.  Press U in the list (or
run M-x nonogram-download-puzzles) at any time to re-download and
update them.

In-game controls:

  SPC or mouse-1   toggle a filled (black) cell
  x   or mouse-3   toggle a cross mark (a cell you believe is empty)
  c   or mouse-2   toggle a dot hint (a cell you suspect is filled)
  arrows / h j k l move the cursor
  n                load a random puzzle
  u                undo the last mark
  q                back to the puzzle list
