Usage:
  (require 'flymake-haml)
  (add-hook 'haml-mode-hook 'flymake-haml-load)

`sass-mode' is a derived mode of 'haml-mode', so
`flymake-haml-load' is a no-op unless the current major mode is
`haml-mode'.

Uses flymake-easy, from https://github.com/purcell/flymake-easy
