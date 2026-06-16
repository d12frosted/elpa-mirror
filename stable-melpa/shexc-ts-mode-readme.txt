This mode is a tree-sitter based companion to `shexc-mode' (see
shexc-mode.el), built on the grammar at
https://github.com/ericprud/tree-sitter-shexc

It provides:
- syntax highlighting (`treesit-font-lock-rules')
- structure-aware indentation (`treesit-simple-indent-rules')
- line/block commenting (M-; via `comment-dwim')
- imenu index of shape declarations
- "jump to shape definition" / "find references to shape" via `xref'
  (`M-.'/`M-,'/`M-?'), resolving `@<#Shape>', `EXTENDS @<#Shape>',
  `&<#Shape>' and `start = @<#Shape>' references to their
  `shape_expr_decl'.

For documentation on ShExC, see:
https://shex.io/shex-semantics/#shexc
