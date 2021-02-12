This package adds support for credo to flycheck.

To use it, require it and ensure you have elixir-mode set up for flycheck:

  (eval-after-load 'flycheck
    '(flycheck-credo-setup))
  (add-hook 'elixir-mode-hook 'flycheck-mode)
