
Major mode for Jack language developed as part of the Nand2Tetris course from
https://www.nand2tetris.org/.

Features:
- font-locking
- indentation
- structural navigation with tree-sitter objects
- imenu

; Installation:

Install the tree-sitter parser from https://github.com/nverno/tree-sitter-jack.

  (add-to-list 'treesit-language-source-alist
               '(jack "https://github.com/nverno/tree-sitter-jack"))
  (treesit-install-language-grammar 'jack)
