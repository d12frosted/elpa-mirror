
The shared front-end core over the backend, `latex-to-svg-backend'.
It detects LaTeX math in a markup buffer, overlays each occurrence with an
SVG typeset by the backend, and provides equation numbering, `\\eqref' /
`\\ref' resolution, reveal-on-cursor editing, render-on-leave, and theme /
zoom refresh.  Per-markup packages (`latex-to-svg-for-markdown',
`latex-to-svg-for-org-mode', …) are thin adaptors that plug in only what is
markup-specific.

Detection is a regexp scanner (`latex-to-svg-frontend--scan') covering:

  inline    $ … $     \( … \)
  display   $$ … $$    \[ … \]     \begin{env} … \end{env}

plus bare `\\eqref' / `\\ref'.  Each delimiter family can be toggled off
(`latex-to-svg-frontend-detect-dollar-inline' and friends).  A blank
line always bounds a span (LaTeX forbids one inside), which keeps detection
from running away on half-typed input.

What counts as "code" (regions to skip) and how to unfold a jump target are
supplied per-markup through a small buffer-local protocol, all set by an
adaptor's minor mode:

  `latex-to-svg-frontend-exclude-function'  regions where math is ignored
  `latex-to-svg-frontend-reveal-function'   unfold the jump target
  `latex-to-svg-frontend-detect-function'   (escape hatch) replace the scanner

An adaptor sets these and then toggles `latex-to-svg-frontend-mode' (see its
own minor mode, e.g. `latex-to-svg-for-markdown-mode').

Because the backend renders its input *verbatim*, the core passes each
element's source (delimiters and all).  The backend compiles each unique
equation once (content-addressed), color-independent (`--currentcolor',
tinted at display) and size-independent (scaled at display), so previews
re-tint / re-scale straight from cache — with NO LaTeX recompile — on a
theme switch or a text-zoom.

Numbered environments (`equation', `align', …) get their real document-wide
number baked in as a `\\setcounter' prefix (see docs/numbering.md).  `\\eqref'
/ `\\ref' resolve against the `\\label' map and show as plain buffer text
(e.g. `(3)', in the `latex-to-svg-frontend-reference' face; `(??)' when the
target is unknown or was just deleted); they re-resolve on every reconcile,
so they never show a stale number, and are click-to-jump to the defining
equation.

Move point into a preview and it reveals its LaTeX source; leaving re-shows
the preview, or re-renders it if the text changed.  Newly typed math renders
the moment the cursor leaves it (`--render-on-leave', on `post-command-hook'),
never while still inside — so half-typed equations are not compiled.  That
same discrete leave event reconciles numbers and references synchronously;
the debounced `after-change' pass is only the backstop for edits with no
clean leave (delete, paste, undo).
