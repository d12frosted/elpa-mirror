This package implements a nested menu that gives access to all known
minor modes (i.e., those listed in `minor-mode-list').  It can be used
to toggle local and global minor modes, to access mode-specific menus,
and to display information about modes.

This menu is intended as a replacement for the incomplete, yet quite
space consuming, list of enabled minor modes that is displayed in the
mode line by default.  To use the menu like this, enable Minions mode.

Emacs 31 adds support for putting minor-modes in a menu instead of
directly in the mode-line, but that menu is less featureful than the
menu provided by this package.  The built-in menu doesn't list global
modes and because it only lists modes that are already enabled, it
cannot be used to enable additional modes.  It also only lists modes
that define a mode line lighter, so it does not present a complete
list of enabled minor modes.

Instead of, or in addition to, making the Minions menu available in
the mode line, it can be bound globally, for example:

  (keymap-global-set "<S-down-mouse-3>" #'minions-minor-modes-menu)

To list a mode even though the defining library has not been loaded
yet, you must add it to `minor-mode-list' yourself.  Additionally it
must be autoloaded.  For example:

  (when (autoloadp (symbol-function 'glasses-mode))
    (cl-pushnew 'glasses-mode minor-mode-list))

To avoid inserting parenthesis around the modes in the mode-line, set
`mode-line-modes-delimiters' (or `minions-mode-line-delimiters' if you
are using Emacs 30 or older) to nil.
