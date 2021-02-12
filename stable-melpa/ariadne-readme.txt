Ariadne (https://github.com/feuerbach/ariadne) provides a
"go-to-definition" functionality for Haskell.

`ariadne.el' is an Ariadne plugin for Emacs.

Dependencies:

`ariadne.el' depends on `bert.el'
(https://github.com/manzyuk/bert-el), BERT serialization library
for Emacs.

Usage:

The function `ariadne-goto-definition' queries the Ariadne server
about the location of the definition of a name at point and jumps
to that location.  Bind `ariadne-goto-definition' to a key, for
example as follows:

    (require 'ariadne)
    (add-hook 'haskell-mode-hook
              (lambda ()
                (define-key haskell-mode-map "\C-cd" 'ariadne-goto-definition)))
