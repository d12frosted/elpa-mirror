C, C++ and Objective-C support for Flycheck, using Irony Mode.

Usage:

    (eval-after-load 'flycheck
      '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup))
