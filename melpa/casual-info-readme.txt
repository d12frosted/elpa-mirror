NOTICE
This package `casual-info' has been superseded by the package `casual'.
Please update to the `casual' package from either MELPA or MELPA stable. Upon
installation and upgrade of the `casual' package, this package will be
removed.

Casual Info is an opinionated Transient-based porcelain for Emacs Info.

INSTALLATION
(require 'casual-info)
(keymap-set Info-mode-map "C-o" #'casual-info-tmenu)

Alternately with `use-package':
(use-package casual-info
  :ensure nil
  :bind (:map Info-mode-map ("C-o" . 'casual-info-tmenu)))

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
