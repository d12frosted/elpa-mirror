Rewrite GFM (GitHub Flavored Markdown) pipe tables so they fit a
given character width.  Cells that exceed their allocated column
width are word-wrapped by emitting additional pipe-table lines.
The wrapped text is meant for readable source editing and
round-tripping with `markdown-table-wrap-unwrap': wrapped header
lines no longer form valid GFM tables, and wrapped body
continuation lines and spacer lines are parsed as additional
rows by Markdown renderers.

The main entry point is `markdown-table-wrap':

  (markdown-table-wrap TABLE-TEXT WIDTH)
  (markdown-table-wrap TABLE-TEXT WIDTH MAX-CELL-HEIGHT)
  (markdown-table-wrap TABLE-TEXT WIDTH MAX-CELL-HEIGHT STRIP-MARKUP)
  (markdown-table-wrap TABLE-TEXT WIDTH MAX-CELL-HEIGHT STRIP-MARKUP COMPACT)

For rendering the same table at multiple widths (e.g., during
window resize), `markdown-table-wrap-batch' parses and measures
once, then renders at each width:

  (markdown-table-wrap-batch TABLE-TEXT WIDTHS)

To merge continuation rows back into logical rows (e.g., before
re-wrapping at a new width), use `markdown-table-wrap-unwrap':

  (markdown-table-wrap
    (markdown-table-wrap-unwrap WRAPPED-TEXT) NEW-WIDTH)

Features:
- Markup-aware wrapping: bold, italic, links, images, code
  (single and double backtick), and strikethrough spans are
  kept intact across line breaks.
- Graceful degradation: when a column is too narrow for markup
  overhead, markers are dropped and inner text is wrapped as
  plain text, preserving legibility over formatting.
- Waterfill column-width allocation: wider columns get more space
  (proportional to sqrt of content width) but the effect is
  dampened so narrow columns aren't starved.  Monotonic — widening
  the terminal never shrinks any column.
- Alignment preservation (left, right, center).
- Optional cell-height cap with ellipsis truncation.
- Automatic row separators for visual breathing room when wrapping
  occurs (opt out with COMPACT).
- Code-fence awareness: tables inside ``` or ~~~ blocks are
  left untouched.
- Unicode-aware width: CJK, combining characters, and VS16
  emoji measured correctly for terminal alignment.
- Backtick parity guard: cells whose wrapping would produce
  odd backtick counts fall back to single-line, preventing
  font-lock leaking across rows.
- Zero dependencies -- pure Elisp, no `markdown-mode' required.

STRIP-MARKUP controls width measurement: nil (default) measures
raw string width; non-nil strips inline markup first (for use
when `markdown-hide-markup' is enabled).

All public functions use the `markdown-table-wrap-' prefix.
Internal helpers use `markdown-table-wrap--' (double dash).
No `defcustom' is defined -- configuration is passed as
parameters.  The consuming package owns its own customization
variables and passes values through.
