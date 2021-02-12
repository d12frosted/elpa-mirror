A simple mode-line configuration for Emacs.
To enable, put this code in your init file:
(require 'simple-modeline)
(simple-modeline-mode 1)
or
(use-package simple-modeline
  :ensure t
  :hook (after-init . simple-modeline-mode))
