If a tree-sitter grammar is available and installed, use it instead of the
corresponding default mode.  Conversely, when a tree-sitter grammar is not
available and a fallback major mode is available/specified, use it instead.

This package also provides a `treesit-auto-install-all' function, which will
scan for tree-sitter grammars listed in `treesit-auto-recipe-list' that are
not installed or otherwise available on `treesit-extra-load-path'.  Automatic
installation of grammars when visiting a file is controlled by the
`treesit-auto-install' variable, which can be t, nil or `prompt'.  When t,
opening a file with a compatible tree-sitter mode will clone and install the
grammar defined by its recipe, if it isn't already installed.  `prompt' will
display a yes/no question in the minibuffer and wait for confirmation before
attempting the installation.
