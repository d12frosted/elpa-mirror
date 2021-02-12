Minor mode for terminal focus reporting.

This plugin restores `focus-in-hook`, `focus-out-hook` functionality.
Now Emacs can, for example, save when the terminal loses a focus, even if it's inside the tmux.

Usage:

1. Install it from Melpa

2. Add code to the Emacs config file:

      (unless (display-graphic-p)
        (require 'terminal-focus-reporting)
        (terminal-focus-reporting-mode))
