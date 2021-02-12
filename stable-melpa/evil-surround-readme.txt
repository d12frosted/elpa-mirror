This package emulates surround.vim by Tim Pope.
The functionality is wrapped into a minor mode. To enable
it globally, add the following lines to ~/.emacs:

    (require 'evil-surround)
    (global-evil-surround-mode 1)

Alternatively, you can enable evil-surround-mode along a major mode
by adding `turn-on-evil-surround-mode' to the mode hook.

This package uses Evil as its vi layer. It is available from:

    https://github.com/emacs-evil/evil
