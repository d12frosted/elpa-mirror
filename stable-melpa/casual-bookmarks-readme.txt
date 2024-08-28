Casual Bookmarks is an opinionated Transient-based user interface for Emacs Bookmarks.

INSTALLATION
(require 'casual-bookmarks) ;; optional
(keymap-set bookmark-bmenu-mode-map "C-o" #'casual-bookmarks-tmenu)

Alternately with `use-package':
(use-package bookmark
  :ensure nil
  :defer t)
(use-package casual-bookmarks
  :ensure t
  :bind (:map bookmark-bmenu-mode-map
              ("C-o" . casual-bookmarks-tmenu)
              ("S" . casual-bookmarks-sortby-tmenu)
              ("J" . bookmark-jump))
  :after (bookmark))

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
