Provides the `(use-package foo :treesit)' idiom.

Adding the `:treesit' keyword to your package's `use-package'
stanza, causes the corresponding treesit grammar to be downloaded
and installed automatically the first time the package loads.

This is lazily implemented in terms of (or by adding advice to)
Emacs 30+'s built-in mechanisms. Specifically,

- at the time the `use-package' stanza is evaluated, and provided
  the target package is available (or equivalently, in the same
  time frame and under the same preconditions as use-package's
  `:init' clause): an entry is added for the target language in
  `treesit-language-source-alist' unless one already exists;

- before the target package actually loads:
  `treesit-install-language-grammar' is invoked (through advice on
  Emacs' standard functions for treesit support), and does the
  heavy lifting.

The `:treesit' keyword to `use-package' accepts arguments as a
plist, with the same keys as in the `use-package-treesit-recipes' variable
i.e `:lang`, `:url`, `:source-dir`, `:cc` and `:c++` (all others,
including `:library` are ignored). These keywords and their values
set or overwrite the corresponding settings in variable
`use-package-treesit-recipes' for the target package.
