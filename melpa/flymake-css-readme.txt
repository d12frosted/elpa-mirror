Usage:
  (require 'flymake-css)
  (add-hook 'css-mode-hook 'flymake-css-load)

Beware that csslint is quite slow, so there can be a significant lag
between editing and the highlighting of resulting errors.

Like the author's many other flymake-*.el extensions, this code is
designed to configure flymake in a buffer-local fashion, which
avoids the dual pitfalls of 1) inflating the global list of
`flymake-err-line-patterns' and 2) being required to specify the
matching filename extensions (e.g. "*.css") redundantly.

Based mainly on the author's flymake-jslint.el, and using the
error regex from Arne Jørgensen's similar flymake-csslint.el.

Uses flymake-easy, from https://github.com/purcell/flymake-easy
