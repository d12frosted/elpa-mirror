haskell-emacs is a library which allows extending Emacs in haskell.
It provides an FFI (foreign function interface) for haskell functions.

Run `haskell-emacs-init' or put it into your .emacs.  Afterwards just
populate your `haskell-emacs-dir' with haskell modules, which
export functions.  These functions will be wrapped automatically into
an elisp function with the name Module.function.

See documentation for `haskell-emacs-init' for a detailed example
of usage.
