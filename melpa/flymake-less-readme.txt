Usage:
  (require 'flymake-less)
  (add-hook 'less-css-mode-hook 'flymake-less-load)

Beware that lessc is quite slow, so there can be a significant lag
between editing and the highlighting of resulting errors.

Like the author's many other flymake-*.el extensions, this code is
designed to configure flymake in a buffer-local fashion, which
avoids the dual pitfalls of 1) inflating the global list of
`flymake-err-line-patterns' and 2) being required to specify the
matching filename extensions (e.g. "*.css") redundantly.

Uses flymake-easy, from https://github.com/purcell/flymake-easy
