Casual Avy is an opinionated Transient-based menu for Avy.

INSTALLATION
(require 'casual-avy)
(keymap-global-set "M-g" #'casual-avy-tmenu)

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
