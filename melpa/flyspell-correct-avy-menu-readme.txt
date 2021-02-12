This package provides avy-menu interface for flyspell-correct package.

Points of interest are `flyspell-correct-wrapper',
`flyspell-correct-previous' and `flyspell-correct-next'.

Example usage:

  (require 'flyspell-correct-avy-menu)
  (define-key flyspell-mode-map (kbd "C-;") 'flyspell-correct-wrapper)

Or via use-package:

  (use-package flyspell-correct-avy-menu
    :bind ("C-M-;" . flyspell-correct-wrapper)
    :init
    (setq flyspell-correct-interface #'flyspell-correct-avy-menu))
