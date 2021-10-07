Nano modeline is a custome modeline rendered as:
[ status | name (primary)                               secondary ]

It can be displayed on bottom (mode-line) or top (header-line)
depending on nano-modeline-position custom setting.

There are two sets of faces (for active and inactive modelines) that
can be customized (M-x: customize-group + nano-modeline)

- nano-modeline-active-name      / nano-modeline-inactive-name
- nano-modeline-active-primary   / nano-modeline-inactive-primary
- nano-modeline-active-secondary / nano-modeline-inactive-secondary
- nano-modeline-active-status-RO / nano-modeline-inactive-status-RO
- nano-modeline-active-status-RW / nano-modeline-inactive-status-RW
- nano-modeline-active-status-** / nano-modeline-inactive-status-**

Usage example:

M-x: nano-modeline