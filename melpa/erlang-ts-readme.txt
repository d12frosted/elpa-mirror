`erlang-ts-mode' is a tree-sitter powered major mode for editing Erlang.
It derives from `erlang-mode' and progressively replaces its features
with tree-sitter based implementations.

Features:
- Tree-sitter based font-locking (4 levels)
- Tree-sitter based indentation (experimental, opt-in)
- Embedded markdown highlighting in doc attributes (Emacs 30+)
- Imenu support for functions, macros, records, and types
- Everything else inherited from erlang-mode

Install the tree-sitter grammar with:
  M-x erlang-ts-install-grammar

See the README for full documentation.
