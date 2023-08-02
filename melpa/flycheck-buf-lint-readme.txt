Flycheck checker for protocol with buf-build

Usage:

    (eval-after-load 'flycheck
      '(add-hook 'flycheck-mode-hook #'flycheck-buf-lint-setup))
