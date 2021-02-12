
A minor mode which adds a hamburger menu button to the mode line.

Use instead of `menu-bar-mode' to save vertical space.  The
hamburger menu is particularly useful when
`mouse-autoselect-window' (Focus Follows Mouse) is enabled.

## Installation

Add the [MELPA](https://melpa.org/) repository to Emacs.  Then run:

    M-x package-install hamburger-menu

Afterwards, configure as follows:

1. Disable `menu-bar-mode', because having two menus is superfluous:

       M-x customize-set-variable RET menu-bar-mode RET n
       M-x customize-save-customized

2. Add the following to your `~/.emacs'.  This will place the
   hamburger menu button at the very left of your mode line:

       (require 'hamburger-menu)
       (setq mode-line-front-space 'hamburger-menu-mode-line)

3. Restart Emacs.  Enjoy.

On the off chance you consider modifying `mode-line-front-space' to
be overly invasive, you can instead enable
`global-hamburger-menu-mode'.  The downside of the mode is that the
hamburger menu button it provides cannot be nicely aligned at the
left of the mode line.
