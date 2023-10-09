
This package defines a major mode for prisma schema language buffers using
tree-sitter. It provides support for indentation, font-locking, imenu, and
structural navigation.

The tree-sitter grammar compatible with this package can be found at
https://github.com/victorhqc/tree-sitter-prisma.

; Installation:

Install the tree-sitter grammar library from
https://github.com/victorhqc/tree-sitter-prisma, eg.

    (add-to-list
     'treesit-language-source-alist
     '(prisma "https://github.com/victorhqc/tree-sitter-prisma")

and call `treesit-install-language-grammar' to do the installation.
