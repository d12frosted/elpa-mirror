A tree-sitter-based major mode for editing AsciiDoc files.

This mode uses two tree-sitter parsers from
<https://github.com/cathaysia/tree-sitter-asciidoc>:

- `asciidoc' for block-level structure (sections, lists, blocks)
- `asciidoc-inline' for inline formatting (bold, italic, links)

Both parsers operate on the full buffer independently, similar to
the dual-parser pattern used by `markdown-ts-mode'.

Features:
- Syntax highlighting for headings, inline markup, blocks, lists,
  attributes, admonitions, macros, and more
- Imenu support for section navigation
- Outline integration for folding
- Comment support (// line comments)

Quick start:
  (asciidoc-install-grammars)   ; one-time setup
  ;; then open any .adoc file
