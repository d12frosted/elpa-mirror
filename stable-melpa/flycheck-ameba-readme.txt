This package provides static syntax checking support for the Crystal language to the
Flycheck package.  To use it, have Flycheck installed, then add the following
to your init file:

   (require 'flycheck-ameba)
   (add-hook 'ameba-mode 'flycheck-ameba)
