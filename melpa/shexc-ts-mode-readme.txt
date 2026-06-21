This mode is a tree-sitter based companion to `shexc-mode' (see
shexc-mode.el), built on the grammar at
https://github.com/ericprud/tree-sitter-shexc

Shares its `rdf-core.el'/`turtle-ts-mode.el' infrastructure with the
sibling `turtle-ts-mode' (a major mode for Turtle/TriG/N-Triples).
Both currently ship bundled inside this package rather than as
independent MELPA dependencies -- they're new and not yet eligible
for their own MELPA submissions; `Package-Requires' will gain an
`rdf-core' entry once that changes. See the README for the planned
split.

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
