Simple helm interface to tree-sitter.

Currently only C, C++, Python and Rust are supported, but adding more
languages in the future should be trivial.


Usage:
(require 'helm-tree-sitter)
and then (helm-tree-sitter) or (helm-tree-sitter-or-imenu)

A debug utility is also provided:
(require 'helm-tree-sitter-debug)
(helm-tree-sitter-debug)
This works with all modes and simply lists all available nodes
in the existing tree-sitter-tree.
