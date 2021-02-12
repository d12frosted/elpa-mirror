
`ruby-electric-mode' accelerates code writing in ruby by making
some keys "electric" and automatically supplying with closing
parentheses and "end" as appropriate.

This work was originally inspired by a code snippet posted by
[Frederick Ros](https://github.com/sleeper).

Add the following line to enable ruby-electric-mode under
ruby-mode.

    (eval-after-load "ruby-mode"
      '(add-hook 'ruby-mode-hook 'ruby-electric-mode))

Or add the following line for enh-ruby-mode.

    (eval-after-load "enh-ruby-mode"
      '(add-hook 'enh-ruby-mode-hook 'ruby-electric-mode))

Type M-x customize-group ruby-electric for configuration.
