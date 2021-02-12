
This modes puts indentation highlights below the starting character
of a line on subsequent lines, like this:

some line
|   some other line
|   | another line
|   | |                  an indented line
| fourth line
final line

This works in every mode, but is more useful in haskell, which
doesn't require indentation levels to be at multiples of a specific
level.

If the minor mode `hl-indent-mode-blocks' is on, this mode will
instead highlight blocks of indentation like so:

xxxxxxxxxxxxxx
  oooooooooooo
  oooooooooooo
       *******
       *******
    **********
  oooooooooooo
    **********
xxxxxxxxxxxxxx

(where different symbols represent different colours).

To use:

Enable `hl-indent-mode'.

There is also `hl-indent-mode-blocks', but it is less useful
because of limited color contrast, depending on face settings.

Screenshot:

![Screenshot](screenshot.png "Screenshot")

Notes:

- You can customize faces `hl-indent-face' (which is `fringe' by
  default), and also `hl-indent-block-face-1', from 1 to 6.

- To easily see where `hl-indent-mode' puts its highlights, use the
  function `hl-indent--debug-faces' together with either
  `hl-indent-mode' or `hl-indent-mode-blocks'.

- FIXME The mode will refuse to turn on in a very very large file,
  because right now it examines every single line once, which can
  take too long.

- FIXME Indentation highlights override any non-trivial background.
  This is a problem for things like comments that might have a
  background different from the default background. It also
  conflicts with other highlights, like hl-line-mode.
