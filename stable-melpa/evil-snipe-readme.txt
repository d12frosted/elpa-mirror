
Evil-snipe emulates vim-seek and/or vim-sneak in evil-mode.

It provides 2-character versions of evil's f/F/t/T motions, for quick and
more accurately jumping around text, plus incremental highlighting (for
f/F/t/T as well).

To enable globally:

    (require 'evil-snipe)
    (evil-snipe-mode 1)

To replace evil-mode's f/F/t/T functionality with (1-character) sniping:

    (evil-snipe-override-mode 1)

See included README.md for more information.
