Provides a Transient menu interface to a subset of isearch functions.
Said functions are grouped as follows in the following sections:
- Edit Search String
- Replace
- Toggle
- Misc
- Navigation

INSTALLATION
Enter the code below into your init file to load and install
`cc-isearch-menu'.  Tune the keybinding to your taste.

(require 'cc-isearch-menu)
(define-key isearch-mode-map (kbd "<f2>") 'cc-isearch-menu-transient)
