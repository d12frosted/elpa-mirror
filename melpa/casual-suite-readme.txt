An umbrella package to support a single installation point for all Casual
user interfaces. Included are user interfaces for the following packages:

- Bookmarks (casual-bookmarks)
- Calc (casual-calc)
- Dired (casual-dired)
- I-Search (casual-isearch)
- IBuffer (casual-ibuffer)
- Info (casual-info)
- RE-Builder (casual-re-builder)
- Org Agenda (casual-agenda)
- Avy (casual-avy)
- Symbol Overlay (casual-symbol-overlay)
- EditKit (casual-editkit)

INSTALLATION

As this is an umbrella package, it is highly recommended that a deep reading
of the install procedure for each user interface be done beforehand as each of
them have their own recommended customizations to go alongside them.
https://github.com/kickingvegas/casual-suite

The following code is a TL;DR initialization for Casual Suite.
(require 'casual-suite)
(keymap-set calc-mode-map "C-o" #'casual-calc-tmenu)
(keymap-set dired-mode-map "C-o" #'casual-dired-tmenu)
(keymap-set isearch-mode-map "C-o" #'casual-isearch-tmenu)
(keymap-set ibuffer-mode-map "C-o" #'casual-ibuffer-tmenu)
(keymap-set ibuffer-mode-map "F" #'casual-ibuffer-filter-tmenu)
(keymap-set ibuffer-mode-map "s" #'casual-ibuffer-sortby-tmenu)
(keymap-set Info-mode-map "C-o" #'casual-info-tmenu)
(keymap-global-set "M-g" #'casual-avy-tmenu)
(keymap-set reb-mode-map "C-o" #'casual-re-builder-tmenu)
(keymap-set reb-lisp-mode-map "C-o" #'casual-re-builder-tmenu)
(keymap-set bookmark-bmenu-mode-map "C-o" #'casual-bookmarks-tmenu)
(keymap-set org-agenda-mode-map "C-o" #'casual-agenda-tmenu)
(keymap-set symbol-overlay-map "C-o" #'casual-symbol-overlay-tmenu)
(keymap-global-set "C-o" #'casual-editkit-main-tmenu)

NOTE: This package requires `casual-lib' which in turn requires an update of
the built-in package `transient' ≥ 0.6.0. Please customize the variable
`package-install-upgrade-built-in' to t to allow for `transient' to be
updated. For further details, consult the INSTALL section of this package's
README.
