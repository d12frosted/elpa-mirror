This package provides tree-sitter powered major mode for the Unison
programming language (https://www.unison-lang.org/).

Features:
- Syntax highlighting with tree-sitter
- Automatic indentation
- imenu support for navigation
- LSP integration (eglot and lsp-mode)
- Auto-install of tree-sitter grammar
- UCM (Unison Codebase Manager) integration with REPL and commands

Usage:
The mode is automatically activated for .u and .unison files.
For LSP support, install UCM (Unison Codebase Manager) and enable
eglot or lsp-mode.

UCM Keybindings (under C-c C-u prefix):
  C-c C-u r - Open UCM REPL
  C-c C-u a - Add definitions from current file
  C-c C-u u - Update definitions
  C-c C-u t - Run tests
  C-c C-u x - Run a term
  C-c C-u w - Watch current file
  C-c C-u l - Load current file
  C-c C-u e - Send region to REPL
  C-c C-u d - Send definition at point to REPL

Forked from https://github.com/dariooddenino/unison-ts-mode-emacs.
