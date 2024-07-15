An umbrella package to support a single installation point for all Casual
porcelains. Included are porcelains for the following packages:

- Calc (casual-calc)
- Dired (casual-dired)
- I-Search (casual-isearch)
- IBuffer (casual-ibuffer)
- Info (casual-info)
- RE-Builder (casual-re-builder)
- Avy (casual-avy)

INSTALLATION

As this is an umbrella package, it is highly recommended that a deep reading
of the install procedure for each porcelain be done beforehand as each of
them have their own recommended customizations to go alongside them.
https://github.com/kickingvegas/casual-suite

The following code is a TL;DR initialization for Casual Suite.
(require 'casual-suite)
(keymap-set calc-mode-map "C-o" #'casual-calc-tmenu)
(keymap-set dired-mode-map "C-o" #'casual-dired-tmenu)
(keymap-set isearch-mode-map "<f2>" #'cc-isearch-menu-transient)
(keymap-set ibuffer-mode-map "C-o" #'casual-ibuffer-tmenu)
(keymap-set ibuffer-mode-map "F" #'casual-ibuffer-filter-tmenu)
(keymap-set ibuffer-mode-map "s" #'casual-ibuffer-sortby-tmenu)
(keymap-set Info-mode-map "C-o" #'casual-info-tmenu)
(keymap-global-set "M-g" #'casual-avy-tmenu)
(keymap-set reb-mode-map "C-o" #'casual-re-builder-tmenu)
(keymap-set reb-lisp-mode-map "C-o" #'casual-re-builder-tmenu)
