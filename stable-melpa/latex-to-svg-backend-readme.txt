
A small, buffer-agnostic engine that turns a LaTeX math string into an
SVG image suitable for overlaying in an Emacs buffer.  It is the
rendering core extracted from `agent-shell-math-renderer'; front-ends
(agent-shell's markdown renderer, an Org preview mode, ...) do their own
equation detection and image *placement* and delegate the actual
typesetting here.

Design (why it is cheap to recolor and rescale):

  * Equations are compiled with `latex' + `dvisvgm' to a standalone SVG,
    content-addressed on disk (SHA-1 of LaTeX + preamble + style).  Each
    unique equation therefore compiles at most once, ever, and the cache
    is shared across every front-end.

  * The on-disk SVG is COLOR-INDEPENDENT: dvisvgm `--currentcolor' emits
    the default ink as the literal token `currentColor', which is
    substituted with the buffer foreground at display time.  A theme
    switch therefore re-tints from cache with no recompile.  The image
    background is transparent, so it always matches the buffer.

  * The on-disk SVG is SIZE-INDEPENDENT: it is compiled at dvisvgm
    `--scale=1' (natural point dimensions, glyphs as outline paths) and
    scaled at display time via `create-image' :scale, computed from the
    buffer font height so equations track the font — again no recompile.

  * The preamble is PRECOMPILED once to a LaTeX format file (`.fmt') via
    the `mylatexformat' package, then loaded by every equation compile
    with a `%&' first line (see `latex-to-svg-backend-precompile').  This skips
    re-parsing the class and packages (amsmath, ...) on each equation, so
    compiles are markedly faster.  It falls back to a full compile when
    `mylatexformat' is unavailable or the dump fails.

  * The cache is SHARDED into 256 subdirectories (by the first two hex
    characters of the content key) so no single directory accumulates
    every equation, and is bounded by an age-limited garbage collector
    (`latex-to-svg-backend-gc') that deletes equations untouched for a
    while and runs automatically about once a day (see
    `latex-to-svg-backend-gc-interval').

Public entry point:

  (latex-to-svg-backend LATEX &key callback color background padding font-height)

LATEX is placed *verbatim* in the document body, so the caller passes
valid body LaTeX and decides inline vs display by the delimiters it uses
(`$x$', `\(x\)', `\[x\]', `\begin{equation}...\end{equation}', ...).
The engine is deliberately unaware of that distinction.

Returns an image now when one can be produced synchronously (cache /
on-disk SVG / placeholder), else nil after scheduling an asynchronous
compile; CALLBACK (a zero-argument function) is invoked once the SVG is
ready, so the caller can re-query and place the image.  Concurrent
requests for the same equation are coalesced onto a single compile.

The optional `:color'/`:background'/`:padding' keys override the
display-time tint, an optional box color behind the equation, and padding
that grows that box beyond the ink (all apply post-compile, no recompile);
a front-end owns the user-facing preference and passes it through.

Helpers a front-end typically needs for its refresh policy:
`latex-to-svg-backend-available-p', `latex-to-svg-backend-appearance',
`latex-to-svg-backend-display-scale', and `latex-to-svg-backend-foreground-color'.
