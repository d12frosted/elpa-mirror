typst-overlay renders Typst math equations as inline overlays.
Equations are compiled asynchronously to SVG with the `typst'
compiler, many per process, and displayed over the source text.  The overlay is hidden
while point is inside an equation, so you can edit the raw source,
and restored when point leaves.

Supported buffers: `typst-ts-mode' and `org-mode' (where $...$ is
treated as Typst math, with the #let code of the Typst export
blocks before it).  Both use the Typst tree-sitter grammar to find
equations.

Usage:

  M-x typst-overlay-mode      enable in the current buffer
  M-x typst-overlay-refresh   re-render overlays manually

Edited equations are rendered again once you stop typing; see
`typst-overlay-idle-refresh-delay'.

Equations that fail to compile are reported to Flymake, in org
buffers by default; see `typst-overlay-use-flymake'.

Requires the `typst' executable on PATH and the Typst tree-sitter
grammar.  See `customize-group' `typst-overlay' for options.
