Override the parent keymap of `function-key-map' for the preferred input method
to translate input sequences to the default system layout (English), so we can
use Emacs bindings while the non-default system layout is active.
Usage example:
(use-package reverse-im
  :ensure t
  :custom
  (reverse-im-input-methods '("ukrainian-computer")) ; put your input-method(s) here
  :config
  (reverse-im-mode t))

or, alternatively, add the library to your `load-path'
and (reverse-im-activate "ukrainian-computer") manually
