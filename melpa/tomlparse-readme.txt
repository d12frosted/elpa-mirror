This is a tree sitter based reader for TOML data.  It provides three
functions

* `tomlparse-file' – to read TOML data from a file
* `tomlparse-buffer' - to read TOML data from the current buffer
* `tomlparse-string' - to read TOML data a string

All the functions return the TOML data as a hash table similar to
`json-parse-string'.  Just like with `json-parse-string' you can also get the
TOML data as a `alist' or `plist' object.  See the documentation of the
functions for details.

In order to use it, the tree sitter module must be compiled into Emacs and
the TOML language grammar must be installed.  Make sure to pick the latest
TOML grammar: https://github.com/tree-sitter-grammars/tree-sitter-toml You
can install toml grammar by the following snippet in your startup file

(add-to-list
 'treesit-language-source-alist
 '(toml "https://github.com/tree-sitter-grammars/tree-sitter-toml"))
(unless (treesit-language-available-p 'toml)
  (treesit-install-language-grammar 'toml))
