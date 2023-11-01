


1 blueprint-ts-mode
═══════════════════

  Major mode for Blueprint
  (<https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/>) based
  on Treesitter.


2 Installation
══════════════

  You need Emacs version >= 29. Your Emacs also needs to be compiled
  with Treesitter support (`--with-tree-sitter') which you can check
  with the variable `system-configuration-options'.

  Get the grammar:
  ┌────
  │ (add-to-list 'treesit-language-source-alist
  │ 	     '(blueprint . (https://github.com/huanie/tree-sitter-blueprint)))
  │ (treesit-install-language-grammar 'blueprint)
  └────

  Install `blueprint-ts-mode' from NONGNU ELPA. `package-install
  blueprint-ts-mode'.


3 Features
══════════

  • Font Lock
  • Indentation
  • Eglot integration
  • Treesitter based navigation

    These features still need improvement. Feedback and contributions
    are welcome!


4 Reporting Bugs
════════════════

  Please make sure that you have the latest grammar installed from
  <https://github.com/huanie/tree-sitter-blueprint>.
