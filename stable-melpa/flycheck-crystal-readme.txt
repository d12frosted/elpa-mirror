This package provides error-checking support for the Crystal language to the
Flycheck package.  To use it, have Flycheck installed, then add the following
to your init file:

   (require 'flycheck-crystal)
   (add-hook 'crystal-mode-hook 'flycheck-mode)
