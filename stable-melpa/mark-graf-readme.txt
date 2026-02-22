mark-graf is a modern WYSIWYG-style markdown editing mode for Emacs 30+.
It provides inline WYSIWYG rendering using the text-property-based
approach of org-modern.

Features:
- Inline rendering of markdown using text properties and overlays
- Three editing paradigms: line-at-point, block-at-point, hybrid
- Full GFM support including tables, task lists, and fenced code blocks
- Image and diagram rendering
- Built-in HTML export with optional Pandoc integration

Usage:
  (require 'mark-graf)
  ;; Automatically activates for .md files

Customization:
  M-x customize-group RET mark-graf RET
