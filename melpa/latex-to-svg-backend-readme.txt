
A small, buffer-agnostic backend that turns a LaTeX math string into an
SVG image suitable for overlaying in an Emacs buffer.  It is the
rendering backend behind `agent-shell-math-renderer' (math in agent-shell's
chat output) and the `latex-to-svg' preview stack (Org and Markdown).
A front-end finds the equations and places the images; the typesetting,
caching and sizing happen here.

Design (why it is cheap to recolor and rescale):

  * Equations are compiled with `latex' + `dvisvgm' to a standalone SVG,
    named on disk after its own content (SHA-1 of LaTeX + preamble +
    style).  Each unique equation therefore compiles at most once, and
    the cache is shared across every front-end.

  * A second engine, RaTeX's `render-svg', needs no TeX installation
    and typesets the math KaTeX supports; a caller chooses it per call
    with `:engine ratex'.  It produces the same color- and
    size-independent SVG; the `.fmt' precompilation and compile metadata
    below are the LaTeX engine's.

  * A third engine, `:engine texres', runs LaTeX through texres, a TeX
    distribution in a single executable, and converts its PDF with
    `pdftocairo'.  It reads the LaTeX engine's preamble and has its own
    `.fmt' file and compile metadata.

  * The on-disk SVG is COLOR-INDEPENDENT: dvisvgm `--currentcolor' emits
    the default ink as the literal token `currentColor', which is
    substituted with the caller's `:color' at display time.  A theme
    switch therefore re-tints from cache with no recompile.  The image
    background is transparent, so it always matches the buffer.

  * The on-disk SVG is SIZE-INDEPENDENT: it is compiled at dvisvgm
    `--scale=1' (natural point dimensions, glyphs as outline paths) and
    given its width in pixels at display time, computed from the
    x-height of the text around it, so equations track the font — again
    no recompile.  An inline equation's baseline sits on the line's.

  * The preamble is PRECOMPILED once to a LaTeX `.fmt' file with TeX's
    `\dump', then loaded by every equation compile with a `%&' first
    line (see `latex-to-svg-backend-precompile').  This skips re-parsing
    the class and packages (amsmath, ...) on each equation, so compiles
    are markedly faster.  It falls back to a full compile when the dump
    fails.

  * The cache is SHARDED into 256 subdirectories (by the first two hex
    characters of the content key) so no single directory accumulates
    every equation, and is bounded by an age-limited garbage collector
    (`latex-to-svg-backend-gc') that deletes equations untouched for a
    while and runs automatically about once a day (see
    `latex-to-svg-backend-gc-interval').

Public entry point:

  (latex-to-svg-backend LATEX &key callback metadata engine fallback
                        quiet rescale-by color background padding
                        x-height)

LATEX is placed *verbatim* in the document body, so the caller passes
valid body LaTeX and decides inline vs display by the delimiters it uses
(`$x$', `\(x\)', `\[x\]', `\begin{equation}...\end{equation}', ...).
The backend is deliberately unaware of that distinction.

Returns an image now when one can be produced synchronously (cache /
on-disk SVG), else nil after scheduling an asynchronous
compile; CALLBACK (a zero-argument function) is invoked once the SVG is
ready, so the caller can re-query and place the image.  Concurrent
requests for the same equation are coalesced onto a single compile.

A formula the engine rejects is recorded and not compiled again;
`:fallback latex' typesets it with LaTeX instead, and
`latex-to-svg-backend-engine-used' says which engine drew a picture.

The backend reads no faces and no frames.  The caller passes the
tint as `:color' and the x-height of the text as `:x-height', both
read on the frame that shows its buffer; `:background' and `:padding'
add a box behind the equation and grow it beyond the ink -- one number
for all four sides, or a list of one to four numbers in CSS order, so a
left-only gutter is (0 0 0 6).  All apply post-compile, no recompile.

Helpers a front-end typically needs for its refresh policy:
`latex-to-svg-backend-available-p' and
`latex-to-svg-backend-image-width'.
