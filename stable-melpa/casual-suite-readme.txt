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
(define-key calc-mode-map (kbd "C-o") #'casual-calc-tmenu)
(define-key dired-mode-map (kbd "C-o") #'casual-dired-tmenu)
(define-key info-mode-map (kbd "C-o") #'casual-info-tmenu)
(keymap-global-set "M-g" #'casual-avy-tmenu)
(define-key isearch-mode-map (kbd "<f2>") 'cc-isearch-menu-transient)
