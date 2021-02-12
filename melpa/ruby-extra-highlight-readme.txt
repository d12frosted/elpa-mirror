This package highlights Ruby method and block parameters.

Usage:

The minor mode `ruby-extra-highlight-mode' adds highlighting rules
to the current buffer for highlighting method and block parameters.

The easiest way automatically enable it for Ruby buffers is to add
the following to a suitable init file:

    (add-hook 'ruby-mode-hook #'ruby-extra-highlight-mode)
