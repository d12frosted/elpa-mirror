This package adds support for dogma to flycheck.

To use it, require it and ensure you have elixir-mode set up for flycheck:

  (eval-after-load 'flycheck
    '(flycheck-dogma-setup))
  (add-hook 'elixir-mode-hook 'flycheck-mode)
