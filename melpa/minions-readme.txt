This package implements a nested menu that gives access to all known
minor modes (i.e., those listed in `minor-mode-list').  It can be used
to toggle local and global minor modes, to access mode-specific menus,
and to display information about modes.

This menu is intended as a replacement for the incomplete, yet quite
space consuming, list of enabled minor modes that is displayed in the
mode line by default.  To use the menu like this, enable Minions mode.

Alternatively the menu can be bound globally, for example:

  (global-set-key [S-down-mouse-3] 'minions-minor-modes-menu)

To list a mode even though the defining library has not been loaded
yet, you must add it to `minor-mode-list' yourself.  Additionally it
must be autoloaded.  For example:

  (when (autoloadp (symbol-function 'glasses-mode))
    (cl-pushnew 'glasses-mode minor-mode-list))
