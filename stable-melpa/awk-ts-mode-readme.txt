
This package defines a tree-sitter enabled major modes awk that provides
support for indentation, font-locking, imenu, and structural navigation.

The tree-sitter grammar compatible with this package can be found at
https://github.com/Beaglefoot/tree-sitter-awk.

; Installation:

For a simple way to install the tree-sitter grammar libraries,
add the following entry to `treesit-language-source-alist':

    (add-to-list
     'treesit-language-source-alist
     '(awk "https://github.com/Beaglefoot/tree-sitter-awk")

and call `treesit-install-language-grammar' to do the installation.
