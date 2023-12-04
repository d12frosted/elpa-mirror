jtsx is a package for editing JSX or TSX files.  It provides jtsx-jsx-mode
and jtsx-tsx-mode major modes implemented respectively on top of js-ts-mode
and tsx-ts-mode, benefiting thus from the new tree-sitter built-in feature.

Summary of features and fixes:
* Fix commenting and indenting issues with JSX code in Emacs built-in
js-ts-mode and tsx-ts-mode modes
* Refactoring: moving, wrapping, renaming `JSX` elements
* Jumping between opening and closing `JSX` elements
* Electric JSX closing element
* Code folding

Note on the default configuration:
This package doesn't automatically register its provided major modes into
auto-mode-alist.  It is up to the user to do the association, letting him/her
choose which of the provided modes he/she wants to use.  Same consideration
applies for command shortcuts.
