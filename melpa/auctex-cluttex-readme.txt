This package provides ClutTeX support for AUCTeX package.

To use this package, add following code to your init file.

 (add-hook 'plain-TeX-mode-hook
           #'auctex-cluttex-mode)
 (add-hook 'LaTeX-mode-hook
           #'auctex-cluttex-mode)
