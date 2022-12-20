This package provides the ability to highlight untested code
according to simplecov by using its JSON serialized data.

See function `simplecov-show-coverage'.

Currently, you must manually run your tests with singlecov
activated.

If you're doing lots of coverage work, you might want to define
keybindings such as:

  (define-key enh-ruby-mode-map (kbd "C-c r") 'simplecov-show-coverage)
  (define-key enh-ruby-mode-map (kbd "C-c R") 'simplecov-clear)
