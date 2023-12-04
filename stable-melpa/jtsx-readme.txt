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
