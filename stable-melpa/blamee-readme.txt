
blamee.el displays `git blame' information inline between the
display-line-numbers gutter and the source text.  Consecutive lines
sharing the same commit are grouped into a chunk; only the first line
of each chunk shows the blame prefix, the rest show a blank spacer of
the same width so the source code stays aligned.

The inline prefix defaults to a small date + author layout,
but its visible columns can be customized.  A per-commit background
color identifies chunk boundaries at a glance.  When point enters a
blamed line, a child-frame popup (or echo area on TTY) shows the
full commit detail: author, full timestamp, 12-char hash and
summary.

Usage:

  (require 'blamee)
  (global-blamee-mode 1)   ; auto-enable in file buffers inside a git tree

  M-x blamee-mode          ; toggle in a single buffer

See README.md for installation recipes, customization and screenshots.
