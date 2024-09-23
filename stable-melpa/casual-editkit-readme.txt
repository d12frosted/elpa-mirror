Casual EditKit is a Transient user interface toolkit for Emacs editing.

INSTALLATION
(require 'casual-editkit) ;; optional
(keymap-global-set "C-o" #'casual-editkit-main-tmenu)

Alternately with `use-package':
(use-package casual-editkit
  :ensure nil
  :bind (("C-o" . casual-editkit-main-tmenu)))

Alternate bindings to consider are "M-o" and "F10". Choose whatever binding
best suits you.

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
