Provides a Transient menu interface to a subset of isearch functions.
Said functions are grouped as follows in the following sections:
- Edit Search String
- Replace
- Toggle
- Misc
- Navigation

INSTALLATION
Enter the code below into your init file to load and install
`casual-isearch-tmenu'.  Tune the keybinding to your taste.

(require 'casual-isearch)
(keymap-set isearch-mode-map "C-o" #'casual-isearch-tmenu)

Alternately with `use-package':
(use-package casual-isearch
  :ensure t
  :bind (:map isearch-mode-map ("C-o" . casual-isearch-tmenu)))
