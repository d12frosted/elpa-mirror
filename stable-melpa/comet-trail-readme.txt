This package provides a comet trail effect for the cursor.  When
the cursor moves, a short animated comet travels along the
geometric line between the old and new positions.

It highlights the background of characters that fall along the
path, correctly handling visual line wrapping
(`visual-line-mode', word-wrap, `toggle-truncate-lines').

The core idea: given two buffer positions, compute their visual
(column, row) coordinates on screen, trace a line between them
using Bresenham's algorithm, then map each cell back to a buffer
position and animate a sliding comet with ease-out brightness.

Usage:

  (require 'comet-trail)
  (add-hook 'prog-mode-hook #'comet-trail-mode)
