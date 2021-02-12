Require this script

  (require 'phi-rectangle)

and call function "phi-rectangle-mode". Then following commands are
available

- [C-RET] phi-rectangle-set-mark-command

  Activate the rectangle mark.

- phi-rectangle-kill-region (replaces "kill-region")

  A dwim version of "kill-region". If the rectangle mark is active,
  kill rectangle. If the normal mark is active, kill region as usual.
  Otherwise, kill whole line.

- phi-rectangle-kill-ring-save (replaces "kill-ring-save")

  A dwim version of "kill-ring-save" like "phi-rectangle-kill-region".

- phi-rectangle-yank (replaces "yank")

  A dwim version of "yank". If the last killed object is a rectangle,
  yank rectangle. Otherwise yank a kill-ring item as usual.
