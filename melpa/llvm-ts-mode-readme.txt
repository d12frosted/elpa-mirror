
Major mode for LLVM using tree-sitter.

Features:
- font-locking
- indentation
- structural navigation with tree-sitter objects
- imenu

; Installation:

Install the tree-sitter parser from
https://github.com/benwilliamgraham/tree-sitter-llvm.

  (add-to-list 'treesit-language-source-alist
               '(llvm "https://github.com/benwilliamgraham/tree-sitter-llvm"))
  (treesit-install-language-grammar 'llvm)
