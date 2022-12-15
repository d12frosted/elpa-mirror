[![NonGNU ELPA](https://elpa.nongnu.org/nongnu/lorem-ipsum.svg)](https://elpa.nongnu.org/nongnu/lorem-ipsum.html)

# Lorem Ipsum for Emacs #

Add filler lorem ipsum text in Emacs.

## Installation

**NonGNU ELPA or MELPA**

This package is available via [NonGNU ELPA](https://elpa.nongnu.org/)
and MELPA.  You can install it by calling:

    M-x package-install RET lorem-ipsum RET

That's it, all the functions you need are `autoload`ed.

**Manual Installation**

Add `lorem-ipsum.el` to your `load-path`.  Finally, the package must
be required:

    (require 'lorem-ipsum)

## Setup

Use the default keybindings by adding the following to your .emacs
file:

    (lorem-ipsum-use-default-bindings)


This will setup the following keybindings:

Key Binding | Function
------------|------------------------------
`C-c l p`   | `lorem-ipsum-insert-paragraphs`
`C-c l s`   | `lorem-ipsum-insert-sentences`
`C-c l l`   | `lorem-ipsum-insert-list`

If you want different keybinding, say you want the prefix `C-c C-l`,
use a variation of the following:

    (global-set-key (kbd "C-c C-l s") 'lorem-ipsum-insert-sentences)
    (global-set-key (kbd "C-c C-l p") 'lorem-ipsum-insert-paragraphs)
    (global-set-key (kbd "C-c C-l l") 'lorem-ipsum-insert-list)
