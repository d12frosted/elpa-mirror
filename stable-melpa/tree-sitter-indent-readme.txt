Use Tree-sitter as backend to source code indentation.

Provide an `indent-line-function` using the emacs-tree-sitter package
Usage (for Rust language):

(require 'tree-sitter-indent)
(tree-sitter-require 'rust)

(add-hook 'rust-mode-hook #'tree-sitter-indent-mode)

The code in this package was based on Atom implementation of line indenting using
Tree-sitter at https://github.com/atom/atom/pull/18321/

See Atom's "Creating a Grammat" page for therminology
https://flight-manual.atom.io/hacking-atom/sections/creating-a-grammar/
