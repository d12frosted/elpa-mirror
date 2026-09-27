
Markdown adaptor for `latex-to-svg-frontend': a thin layer that tells the
shared core what counts as "code" in a Markdown buffer (so math inside code
is not previewed) and enables the core.  All the actual work — detection,
overlays, numbering, references, reveal-on-cursor, refresh — lives in
`latex-to-svg-frontend'.

Usage:

  (add-hook 'markdown-ts-mode-hook #'latex-to-svg-for-markdown-mode)

Per-buffer settings (rescale factors, delimiter toggles, …) are the core's
buffer-local variables; set them in the same hook, e.g.

  (setq-local latex-to-svg-frontend-rescale-display 1.25)
