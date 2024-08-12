Casual Dired is an opinionated Transient-based user interface for Emacs Dired.

INSTALLATION
(require 'casual-dired)
(keymap-set dired-mode-map "C-o" #'casual-dired-tmenu)
(keymap-set dired-mode-map "s" #'casual-dired-sort-by-tmenu) ; optional
(keymap-set dired-mode-map "/" #'casual-dired-search-replace-tmenu) ; optional

Alternately, install using `use-package':
(use-package casual-dired
  :ensure t
  :bind (:map dired-mode-map
              ("C-o" . #'casual-dired-tmenu)
              ("s" . #'casual-dired-sort-by-tmenu)
              ("/" . #'casual-dired-search-replace-tmenu)))
