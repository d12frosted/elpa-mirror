Purpose:

To support completion for GHCi commands (like :load, :module, :set
etc.) in inferior-haskell buffers.

Installation:

To turn on GHCi commands completion in inferior-haskell buffers,
add this to .emacs:

    (add-hook 'inferior-haskell-mode-hook 'turn-on-ghci-completion)

Otherwise, call `turn-on-ghci-completion'.

You may also want to set `ghci-completion-ghc-pkg-additional-args'
to the list of additional argument to supply to `ghc-pkg'.  For
example, this variable can be used to specify which database (user
or global) or which package config file to use.

Limitations:

* This package is developed for Emacs 24 and it probably only works
  with Emacs 24.  In particular, we rely on lexical bindings, which
  have been introduced in Emacs 24, and on `pcomplete', which is
  effectively broken in 23.2.

* Only the following commands are supported: :add, :browse[!], :cd,
  :edit, :load, :module, :set, :unset, :show.  It would be nice to
  have shell completion for :!, for example.

* The starred versions of the commands :add, :browse[!], :load, and
  :module are not supported, partly because I don't use them, and
  partly because, for example, :module offers completion only on
  the exposed modules in registered packages in both the global and
  user databases, and for these :module *<mod> is meaningless.

* :set and :unset support only a subset of all GHC flags: language
  extensions, warnings, and debugging options.  Adding completion
  for other flags is trivial.  It would be nice, however, to be
  able to generate the list of all GHC flags programmatically.
