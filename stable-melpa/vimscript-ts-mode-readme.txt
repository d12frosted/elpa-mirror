
This package defines a major mode for vimscript buffers using the
tree-sitter parser from https://github.com/neovim/tree-sitter-vim.

It provides the following features:
 - indentation
 - font-locking
 - imenu
 - structural navigation using tree-sitter objects

When parsers are available for lua or ruby, they will be used to
parse embedded code blocks. See `lua-ts-mode' and `ruby-ts-mode'
for more information about those parsers.
