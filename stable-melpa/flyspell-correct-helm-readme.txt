This package provides helm interface for flyspell-correct package.

Points of interest are `flyspell-correct-wrapper',
`flyspell-correct-previous' and `flyspell-correct-next'.

Example usage:

  (require 'flyspell-correct-helm)
  (define-key flyspell-mode-map (kbd "C-;") 'flyspell-correct-wrapper)

Or via use-package:

  (use-package flyspell-correct-helm
    :bind ("C-M-;" . flyspell-correct-wrapper)
    :init
    (setq flyspell-correct-interface #'flyspell-correct-helm))
