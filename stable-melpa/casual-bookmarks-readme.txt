Casual Bookmarks is an opinionated Transient-based porcelain for Emacs Bookmarks.

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
