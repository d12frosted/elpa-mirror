To use this package, simply install and add this to your init.el
(require 'nerd-icons-dired)
(add-hook 'dired-mode-hook 'nerd-icons-dired-mode)

or use use-package:
(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))

This package is inspired by
- `all-the-icons-dired': https://github.com/jtbm37/all-the-icons-dired
