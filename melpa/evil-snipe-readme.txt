
Evil-snipe emulates vim-seek and/or vim-sneak in evil-mode.

It provides 2-character motions for quickly (and more accurately) jumping around
text, compared to evil's built-in f/F/t/T motions, incrementally highlighting
candidate targets as you type.

To enable globally:

    (require 'evil-snipe)
    (evil-snipe-mode 1)

To replace evil-mode's f/F/t/T functionality with (1-character) sniping:

    (evil-snipe-override-mode 1)

See included README.md for more information.
