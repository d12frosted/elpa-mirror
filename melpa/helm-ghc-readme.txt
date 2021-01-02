This is a Helm datasource for GHC-mod errors. When ghc-mod places
at least one error overlay in the buffer, running `helm-ghc-errors'
will open a buffer that lists the errors.

To use it, simply bind the command to a key in `haskell-mode-map'
(because ghc-mod isn't yet a proper minor mode). For example:
(add-hook 'haskell-mode-hook
(lambda () (define-key haskell-mode-map (kbd "C-c ?") 'helm-ghc-errors)))
