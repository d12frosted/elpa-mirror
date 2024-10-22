NOTICE
This package `casual-dired' has been superseded by the package `casual'.
Please update to the `casual' package from either MELPA or MELPA stable. Upon
installation and upgrade of the `casual' package, this package will be
removed.

Casual Dired is an opinionated Transient-based user interface for Emacs Dired.

INSTALLATION
(require 'casual-dired)
(keymap-set dired-mode-map "C-o" #'casual-dired-tmenu)
(keymap-set dired-mode-map "s" #'casual-dired-sort-by-tmenu) ; optional
(keymap-set dired-mode-map "/" #'casual-dired-search-replace-tmenu) ; optional

Alternately, install using `use-package':
(use-package casual-dired
  :ensure nil
  :bind (:map dired-mode-map
              ("C-o" . #'casual-dired-tmenu)
              ("s" . #'casual-dired-sort-by-tmenu)
              ("/" . #'casual-dired-search-replace-tmenu)))

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
