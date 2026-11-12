A tree-sitter-based major mode for editing AsciiDoc files.

This mode uses two tree-sitter parsers from
<https://github.com/bovinemagnet/tree-sitter-asciidoc>:

- `asciidoc' for block-level structure (sections, lists, blocks)
- `asciidoc-inline' for inline formatting (bold, italic, links)

The block parser covers the whole buffer, and the inline parser is
embedded into the parts of it that hold inline content (paragraphs,
titles, list items, table cells).

Features:
- Syntax highlighting for headings, inline markup, blocks, lists,
  attributes, admonitions, macros, and more
- Imenu support for section navigation
- Outline integration for folding
- Cross-reference and link navigation, including cross-file Antora and
  relative xref targets (RET, mouse, C-c C-o, or xref)
- Comment support (// line comments)

Quick start:
  (asciidoc-install-grammars)   ; one-time setup
  ;; then open any .adoc file
