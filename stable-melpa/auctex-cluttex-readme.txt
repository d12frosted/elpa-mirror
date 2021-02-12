This package provides ClutTeX support for AUCTeX package.

To use this package, add following code to your init file.

 (with-eval-after-load 'tex
   (auctex-cluttex-mode))

If you want to use ClutTeX as default command, add following code
to your init file.

 (add-hook 'plain-TeX-mode-hook
           #'auctex-cluttex-set-command-default)
 (add-hook 'LaTeX-mode-hook
           #'auctex-cluttex-set-command-default)
