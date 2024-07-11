Casual Dired is an opinionated Transient-based porcelain for Emacs Dired.

INSTALLATION
(require 'casual-dired)
(keymap-set dired-mode-map "C-o" #'casual-dired-tmenu)
(keymap-set dired-mode-map "s" #'casual-dired-sort-by-tmenu) ; optional
