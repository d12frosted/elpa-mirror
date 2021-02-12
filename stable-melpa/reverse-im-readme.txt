Overrides `function-key-map' parent for preferred input-method
to translate input sequences the default system layout (english)
so we can use Emacs bindings while non-default system layout is active.

Usage example:
(use-package reverse-im
  :ensure t
  :custom
  (reverse-im-input-methods '("russian-computer")) ; use your input-method(s) here
  :config
  (reverse-im-mode t))

or, alternatively, add the library to your load-path and
(reverse-im-activate "russian-computer")
