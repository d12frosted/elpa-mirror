NOTICE
This package `casual-calc' has been superseded by the package `casual'.
Please update to the `casual' package from either MELPA or MELPA stable. Upon
installation and upgrade of the `casual' package, this package will be
removed.

Casual Calc is an opinionated Transient-based user interface for Emacs Calc.

INSTALLATION
(require 'casual-calc)
(keymap-set calc-mode-map "C-o" #'casual-calc-tmenu)
(keymap-set calc-alg-map "C-o" #'casual-calc-tmenu)

Alternately using `use-package':
(use-package calc
  :defer t)
(use-package casual-calc
  :ensure nil
  :bind (:map
         calc-mode-map
         ("C-o" . casual-calc-tmenu)
         :map
         calc-alg-map
         ("C-o" . casual-calc-tmenu))
  :after (calc))

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
