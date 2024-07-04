An umbrella package to support a single installation point for all Casual
porcelains. Included are porcelains for the following packages:

- Calc (casual-calc)
- I-Search (casual-isearch)
- Dired (casual-dired)
- Avy (casual-avy)
- Info (casual-info)

INSTALLATION

As this is an umbrella package, it is highly recommended that a deep reading
of the install procedure for each porcelain be done beforehand as each of
them have their own recommended customizations to go alongside them.
https://github.com/kickingvegas/casual-suite

The following code is a TL;DR initialization for Casual Suite.
(require 'casual-suite)
(keymap-set calc-mode-map "C-o" #'casual-calc-tmenu)
(keymap-set dired-mode-map "C-o" #'casual-dired-tmenu)
(keymap-set Info-mode-map "C-o" #'casual-info-tmenu)
(keymap-global-set "M-g" #'casual-avy-tmenu)
(keymap-set isearch-mode-map "<f2>" #'cc-isearch-menu-transient)
