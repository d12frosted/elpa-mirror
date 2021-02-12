haskell-emacs-text.el provides nearly all haskell functions from
Data.Text.  It uses `haskell-emacs' to register these functions.

If you haven't installed this package via melpa, then add the path
to this package to your `load-path' (for example in your .emacs).
Afterwards run M-x haskell-emacs-init.

(Text.tails "EMACS")
  => ("EMACS" "MACS" "ACS" "CS" "S" "")

If you want to use these functions in your library, put there the
following:

(require 'haskell-emacs-text)
(eval-when-compile (haskell-emacs-init))

See documentation for `haskell-emacs-init' for more info.
