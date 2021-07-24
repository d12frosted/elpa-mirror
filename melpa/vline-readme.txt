put followings your .emacs
  (require 'vline)

if you display a vertical line, type M-x vline-mode.  `vline-mode' doesn't
effect other buffers, because it is a buffer local minor mode.  if you hide
a vertical line, type M-x vline-mode again.

if you display a vertical line in all buffers, type M-x vline-global-mode.

`vline-style' provides a display style of vertical line.  see
`vline-style' docstring.

if you don't want to visual line highlighting (ex.  for performance
issue), please to set `vline-visual' to nil.

if you don't want to use timer (ex.  you want to highlight column
during moving cursors), please to set `vline-use-timer' to nil.
