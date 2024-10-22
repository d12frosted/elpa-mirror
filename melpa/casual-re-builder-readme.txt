NOTICE
This package `casual-re-builder' has been superseded by the package `casual'.
Please update to the `casual' package from either MELPA or MELPA stable. Upon
installation and upgrade of the `casual' package, this package will be
removed.

Casual RE-Builder is an opinionated Transient-based porcelain for the Emacs regular expression editor.

INSTALLATION
(require 'casual-re-builder) ;; optional
(keymap-set reb-mode-map "C-o" #'casual-re-builder-tmenu)
(keymap-set reb-lisp-mode-map "C-o" #'casual-re-builder-tmenu)

Alternately with `use-package'
(use-package re-builder
  :defer t)
(use-package casual-re-builder
  :ensure nil
  :bind (:map
         reb-mode-map ("C-o" . casual-re-builder-tmenu)
         :map
         reb-lisp-mode-map ("C-o" . casual-re-builder-tmenu))
  :after (re-builder))

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
