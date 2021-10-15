`visual-fill-column-mode' is a small Emacs minor mode that mimics the effect
of `fill-column' in `visual-line-mode'.  Instead of wrapping lines at the
window edge, which is the standard behaviour of `visual-line-mode', it wraps
lines at `fill-column' (or `visual-fill-column-width', if set).  This is
accomplished by widening the margins, which narrows the text area.  When the
window size changes, the margins are adjusted automatically.

When `visual-fill-column-center-text' is set, the text is centered in the
window.  This can also be used in combination with `auto-fill-mode' instead
of `visual-line-mode', or in programming modes.
