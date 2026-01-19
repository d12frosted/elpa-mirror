Provides the `(use-package foo :treesit)' idiom.

Adding the `:treesit' keyword to your package's `use-package'
stanza (otherwise similar to any other `use-package' invocation),
causes the corresponding treesit grammar to be downloaded and
installed automatically the first time the package loads (which may
mean immediately, unless the `use-package' configuration uses
`:defer', `:mode', `:commands' or any of the other keywords that
cause deferred loading).

The `:treesit' keyword accepts at most one plist of arguments, with
the same keys as in the `use-package-treesit-recipes` i.e `:lang`,
`:url`, `:source-dir`, `:cc` or `:c++` (all others, including
`:mode` are ignored). These can amend the settings in variable
`use-package-treesit-recipes' for the package being configured, or
outright replace it if the package is not known in that variable.

Using the `:treesit' keyword in an `use-package' stanza, lazily
prepares to download and compile the tree-sitter grammar out of a
location taken from the `use-package-treesit-recipes`, using Emacs
30+'s built-in mechanisms. Specifically,

- at the time the `use-package' stanza is evaluated, and provided
  the target package is available (or equivalently, in the same
  time frame ad under the same preconditions as use-pacakge's
  `:init' clause): a new is entry is added to
  `treesit-language-source-alist' for the target language (unless
  one already exists),

- before the target package actually loads:
  `treesit-install-language-grammar' is invoked.
