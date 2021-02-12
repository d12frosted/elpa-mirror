Add Objective-C support to Flycheck using Clang.

Usage:

(with-eval-after-load 'flycheck
  (add-hook 'flycheck-mode-hook #'flycheck-objc-clang-setup))
