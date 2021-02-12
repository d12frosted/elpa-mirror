This package used to popup a context edit menu in Emacs.
It's convenient for the users those are using mice on hand.
The core start codes of this package are from mouse.el,
which is a part of Emacs release.

# Installation

Add the following codes into your init file to enable it.

  (require 'popup-edit-menu)
  (global-set-key [mouse-3] (popup-edit-menu-stub))

You can change the key binding as you want if you don't want
to active it by mouse right click

# Configuration

If you prefer to show the mode menus below, you can add
the following codes into your init file:

  (setq popup-edit-menu-mode-menus-down-flag t)

or set it in Emacs Customization Group.
