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

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
