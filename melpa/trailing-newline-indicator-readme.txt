`trailing-newline-indicator' provides a minor mode that displays a visual
indicator in the left margin for the trailing newline at the end of a file.
This helps highlight the empty visual line that appears due to the final
newline character.

Optionally, the indicator can also show the next line number (e.g., `⏎ 43'),
giving a clearer sense of where the file ends. The line number display is
controlled by the option:

  M-x customize-variable RET trailing-newline-indicator-show-line-number RET

Note that the line number is only visible when `display-line-numbers-mode'
is active. The `⏎' symbol itself, however, is always visible.

Usage:

  (require 'trailing-newline-indicator)
  (trailing-newline-indicator-mode 1)

To enable globally for all buffers:

  (global-trailing-newline-indicator-mode 1)

This package is safe to load via package.el.
