A tree-sitter based major mode for editing D2 diagram files.
D2 is a modern diagramming language (https://d2lang.com).

This mode provides:
- Syntax highlighting via tree-sitter font-lock
- Indentation
- Imenu navigation (Container, Connection, Node, Class, Table)
- Comment support
- Defun navigation (C-M-a / C-M-e)

Requirements:
- Emacs 30.1 or later with tree-sitter support
- The D2 tree-sitter grammar (ravsii/tree-sitter-d2)

The grammar can be installed via `M-x d2-ts-mode-reinstall-grammar'
or `M-x treesit-install-language-grammar'.
