`meow-tree-sitter' is a package that integrates the treesit library in Emacs
29+ 🌳 with Meow’s motions 🐱. Lots of functionality is ported from
`evil-textobj-tree-sitter'.

To get started, call `meow-tree-sitter-register-defaults' to add the default
keybinds to Meow's "thing" registry. They will now be accessible through
\\[meow-bounds-of-thing] and \\[meow-inner-of-thing], as well as
\\[meow-beginning-of-thing] and \\[meow-end-of-thing].

Evaluate (customize-group 'meow-tree-sitter) to see customization options.
Options are also detailed in the README.org file included in the project
repository.

To register custom keybinds, call `meow-tree-sitter-register-thing' with a
key and type (or list of types). To register custom queries, pass the
optional third argument. Persistent custom queries can be registered in
`meow-tree-sitter-extra-queries'. See the README.org file for details.

Queries in the `queries/' subdirectory were taken from the Helix project
(https://github.com/helix-editor/helix/tree/master/runtime/queries). These
queries are licensed under the GPL-compatible Mozilla Public License 2.0.
