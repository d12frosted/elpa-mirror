Casual RE-Builder is an opinionated Transient-based porcelain for Emacs Re-Builder.

INSTALLATION
(require 'casual-re-builder) ;; optional
(keymap-set reb-mode-map "C-o" #'casual-re-builder-tmenu)
(keymap-set reb-lisp-mode-map "C-o" #'casual-re-builder-tmenu)
