
fringe-current-line is a package to indicate current line on the fringe.
You can use by the following steps.

1. Place this file on your load-path.

2. Add the following code into your init file:

  (require 'fringe-current-line)

3. Activate the mode.

* To enable it only in certain buffer, run `M-x fringe-current-line-mode'.
  Run again and you can disable it.

* To enable it globally, add the following into your init file:

    (global-fringe-current-line-mode 1)

  You can toggle it by running `M-x global-fringe-current-line-mode'.


## Limitation

The indicator is not shown if the cursor is at the end of the buffer and the last line is empty.
