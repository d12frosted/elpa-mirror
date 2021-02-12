This package improves Emacs window system with window moving
commands (not moving focus between windows) and window
splitting commands that takes addtional options to edit a file
or a buffer.

C-x w runs the command smart-window-move, which is an interactive
  function that move the current window to specified directions
  (left/right/above/Below).

C-x W runs the command smart-window-buffer-split, which is an
  interactive function that asks you to choose a buffer and creates
  a new splitted window with coresponding buffer.

C-x M-w runs the command smart-window-file-split, which is an
  interactive function that asks you to choose a file and creates
  a new splitted window with coresponding file.

C-x R runs the command smart-window-rotate, which is an interactive
  function that rotates the windows downwards and rightwards

M-x sw-above allows you to split a window above the current window
  with the buffer you chose.

M-x sw-below allows you to split a window below the current window
  with the buffer you chose.

M-x sw-left allows you to split a window left to the current window
  with the buffer you chose.

M-x sw-right allows you to split a window right to the current window
  with the buffer you chose.

C-x 2 is bounded to sw-below.
C-x 3 is bounded to sw-right.
To switch back to the default key bindings, use the following settings in .emacs
  (setq smart-window-remap-keys 0)
