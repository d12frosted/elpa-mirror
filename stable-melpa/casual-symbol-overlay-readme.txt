Casual Symbol Overlay is a Transient user interface for Symbol Overlay.

INSTALLATION
(require 'casual-symbol-overlay) ;; optional
(keymap-set symbol-overlay-map "C-o" #'casual-symbol-overlay-tmenu)

Alternately with `use-package':
(use-package casual-symbol-overlay
  :ensure nil
  :bind (:map
         symbol-overlay-map
         ("C-o" . casual-symbol-overlay-tmenu)))

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
