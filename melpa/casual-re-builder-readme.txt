Casual RE-Builder is an opinionated Transient-based porcelain for the Emacs regular expression editor.

INSTALLATION
(require 'casual-re-builder) ;; optional
(keymap-set reb-mode-map "C-o" #'casual-re-builder-tmenu)
(keymap-set reb-lisp-mode-map "C-o" #'casual-re-builder-tmenu)

Alternately with `use-package'
(use-package re-builder
  :defer t)
(use-package casual-re-builder
  :ensure t
  :bind (:map
         reb-mode-map ("C-o" . casual-re-builder-tmenu)
         :map
         reb-lisp-mode-map ("C-o" . casual-re-builder-tmenu))
  :after (re-builder))
