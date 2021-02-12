This package adds support for dialyxir to flycheck.

To use it, require it and ensure you have elixir-mode set up for flycheck:

  (eval-after-load 'flycheck
    '(flycheck-dialyxir-setup))
  (add-hook 'elixir-mode-hook 'flycheck-mode)
