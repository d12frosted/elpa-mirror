Setup for this is fairly straightforward. It aims to automatically
configure everything for you. It assumes that you are already using
haskell-mode and flycheck.

If you have use-package setup, this is enough to get nix-haskell
working,

  (use-package nix-haskell
    :hook (haskell-mode . nix-haskell-mode))

Opening a buffer will start a nix process to get your dependencies.
Flycheck and interactive-haskell-mode will start running once they
have been downloaded. This is cached so it will only be done once
for each buffer.

Flycheck will be started automatically. To start a haskell session,
press C-c C-l.

nix-haskell is designed to build package dbs in Nix and then pass
them to GHC. This should avoid some of the security issues in using
‘nix-shell’ automatically in visited directories.
