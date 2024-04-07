Any key activate search.
There are minor modes for major modes: Dired, Package Menu.
Cursor is moved by just pressing any printable characters
of target filename or directory in current folder.

Activation:
- for Dired:	M-x firstly-search-dired-mode RET
- for Package Menu:	M-x firstly-search-package-mode RET
- for Buffer Menu:	M-x firstly-search-buffermenu-mode RET
- for Bookmarks:	M-x firstly-search-bookmarks-mode RET

in Emacs configuration (Init file):
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
C-n and C-p is used during searching as C-s and C-r

How it works:

We use `pre-command-hook' called for any key pressed, if key is
simple and not in "ignore-keys" we activate incremental search with
modified `isearch-search-fun-function' that limit search to bounds
in buffer and some other tweeks.

For Dired default `isearch-search-fun-in-text-property' function is
used for search and only in text which have not nil specified "text
properties".

For modes  based on tabulated-list  (Buffer Menu, Package  menu) we
create  modified version,  `firstly-search-fun-match-text-property'
function that search  only in text which  have specified properties
with specified values.

Many functions use text properties, to investigate them use:
  M-: (print (text-properties-at (point)))

Files:
- first-search.el - common functionality for other files.
- first-search-{dired,package,buffermenu,bookmarks}.el -
  define user available minor modes for specific major modes.
