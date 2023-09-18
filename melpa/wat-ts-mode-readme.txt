
This package defines tree-sitter enabled major modes for webassembly,
`wat-ts-mode' and `wat-ts-wast-mode', for webassembly text format and script
buffers respectively. They provides support for indentation, font-locking,
imenu, and structural navigation.

The tree-sitter grammars compatible with this package can be found at
https://github.com/wasm-lsp/tree-sitter-wasm.

; Installation:

For a simple way to install the tree-sitter grammar libraries,
add the following entries to `treesit-language-source-alist':

   '(wast "https://github.com/wasm-lsp/tree-sitter-wasm" nil "wast/src")
   '(wat "https://github.com/wasm-lsp/tree-sitter-wasm" nil "wat/src")
eg. for wat
    (add-to-list
     'treesit-language-source-alist
     '(wat "https://github.com/wasm-lsp/tree-sitter-wasm" nil "wat/src"))

and call `treesit-install-language-grammar' to do the installation.
