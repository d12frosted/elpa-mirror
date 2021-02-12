Flycheck checker for golangci-lint

Usage:

    (eval-after-load 'flycheck
      '(add-hook 'flycheck-mode-hook #'flycheck-golangci-lint-setup))
