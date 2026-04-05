
Occult (from Latin occultus - "hidden, secret") lets you collapse any
buffer region into a single-line summary using overlays.  The hidden text
remains fully present in the buffer - accessible to `buffer-string',
`buffer-substring-no-properties', org-export, copy/kill, and LLM context
extraction tools.

Usage:
  Select a region and call `occult-toggle' to collapse it.
  Call `occult-toggle' with point on a collapsed fold to expand it.
  Call `occult-reveal-all' to expand all folds in the buffer.
