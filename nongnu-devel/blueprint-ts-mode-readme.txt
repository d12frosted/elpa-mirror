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

  On Emacs 30 and older (or Emacs 31 and newer, if
  `treesit-auto-install-grammar' is set to `never'), there is an
  addition step to get the grammar:
  ┌────
  │ (require 'blueprint-ts-mode)
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
