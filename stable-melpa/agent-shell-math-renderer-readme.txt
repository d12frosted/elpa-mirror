
Display-math support for `agent-shell-markdown': intercept LaTeX
display equations in agent output and overlay them with an image.

Two block-level delimiter styles are recognized, toggled
independently via `agent-shell-math-renderer-delimiters':

  bracket  `\[X\]'    (default; unambiguous)
  dollar   `$$X$$'    (default; safe because matched block-level only)

Inline math `\(X\)' is recognized separately (toggle
`agent-shell-math-renderer-render-inline', default on) and typeset
in text style.  Inline `$X$' is intentionally not matched — a lone
`$' is too common in prose to be safe.

The raw LaTeX is kept in the buffer (so copy / save round-trips the
source) and, on a graphical display, an equation image is layered on
top with a `display' text property.  A blank line can't appear inside
LaTeX display math, so a candidate block whose body would span one is
rejected — this bounds detection and stops a stray delimiter from
swallowing the rest of a streaming response.

Agent responses are rendered through
`agent-shell-markdown-render-functions': agent-shell's markdown
renderer calls `agent-shell-math-renderer--render-hook' once per
streaming chunk, after its own passes.  The hook styles the delimiter
and inline math, renders fenced math, and returns a watermark when an
unclosed block still needs streaming protection.

When `agent-shell-math-renderer-render-submitted-prompts' is non-nil,
submitted prompts are rendered after they are sent, using the same
delimiter, inline-math, and fenced-math handling as agent responses.
This path obtains the same markdown context through agent-shell's
public `agent-shell-markdown-context', so it stays in sync with the
streaming render hook and uses no private agent-shell API.

Equation typesetting is delegated to the `latex-to-svg-backend' library: this
module handles the markdown-specific detection (delimiters, inline
math, fenced blocks, streaming watermark) and image *placement* (via
`display' text properties), while `latex-to-svg-backend' compiles each unique
equation to a color- and size-independent SVG (cached on disk by
content, tinted and scaled at display time).  Compilation is
asynchronous; the image is overlaid when ready.  When the toolchain is
absent or `latex-to-svg-backend-use-placeholder' is set, a placeholder panel
boxing the raw LaTeX is shown instead.  Rendering-engine settings
(LaTeX/dvisvgm programs, preamble, cache directory, font scale,
placeholder / non-graphic behaviour) live in the `latex-to-svg-backend-*'
customization group.
