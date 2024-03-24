Any key activate search. This is modern way of navigation.
There are minor modes for major modes: Dired, Package Menu.
Cursor is moved by just pressing any printable characters
of target filename or directory in current folder.  Do you still
use arrays?

Old dired-explorer.el package do the same.

to activate, add lines to your Emacs configuration (Init file):
(require 'firstly-search-dired)
(require 'firstly-search-package)
(require 'firstly-search-buffermenu)
(require 'firstly-search-bookmarks)
(add-hook 'dired-mode-hook #'firstly-search-dired-mode)
(add-hook 'package-menu-mode-hook #'firstly-search-package-mode)
(add-hook 'Buffer-menu-mode-hook #'firstly-search-buffermenu-mode)
(add-hook 'bookmark-bmenu-mode-hook #'firstly-search-bookmarks-mode)

Customization:

M-x customize-group RET firstly-search
M-x customize-group RET firstly-search-dired
M-x customize-group RET firstly-search-package
M-x customize-group RET firstly-search-buffermenu
M-x customize-group RET firstly-search-bookmarks

Note:
C-n and C-p used during searching as C-s and C-r

Many functions use text properties, to find properties use:
  M-: (print (text-properties-at (point)))

How it works:

We use `pre-command-hook' called for any key pressed, if key is
simple and not in "ignore-keys" we activate incremental search with
modified `isearch-search-fun-function' that limit search to bounds
in buffer and some other tweeks.

For Dired `isearch-search-fun-in-text-property' is used that search
only in text which have not nil specified "text properties".

For modes based on tabulated-list (Buffer Menu, Package menu)
variant of of previous function:
`firstly-search-fun-match-text-property', that search only in text
which have specified properties with specified values.
