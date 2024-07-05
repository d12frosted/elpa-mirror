Casual IBuffer is an opinionated Transient-based porcelain for Emacs IBuffer.

INSTALLATION
(require 'casual-ibuffer) ;; optional
(keymap-set ibuffer-mode-map "C-o" #'casual-ibuffer-tmenu)
(keymap-set ibuffer-mode-map "F" #'casual-ibuffer-filter-tmenu)
(keymap-set ibuffer-mode-map "s" #'casual-ibuffer-sortby-tmenu)
