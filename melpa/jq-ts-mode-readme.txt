
This package defines `jq-ts-mode', a tree-sitter backed major mode for
editing Jq source files. It provides font-lock, imenu, indentation, and
navigation.

The tree-sitter Jq grammar compatible with this package can be found at
https://github.com/nverno/tree-sitter-jq. The grammar can be installed
with `treesit-install-language-grammar' after adding

   '(jq "https://github.com/nverno/tree-sitter-jq" nil nil nil)

to `treesit-language-source-alist'.
