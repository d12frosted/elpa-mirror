Just fold the active region, please.

## How it works

The command `fold-this` visually replaces the current region with `...`.
If you move point into the ellipsis and press enter or `C-g` it is unfolded.

You can unfold everything with `fold-this-unfold-all`.

You can fold all instances of the text in the region with `fold-this-all`.

## Setup

I won't presume to know which keys you want these functions bound to,
so you'll have to set that up for yourself. Here's some example code,
which incidentally is what I use:

    (global-set-key (kbd "C-c C-f") 'fold-this-all)
    (global-set-key (kbd "C-c C-F") 'fold-this)
    (global-set-key (kbd "C-c M-f") 'fold-this-unfold-all)
