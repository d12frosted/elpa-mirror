
LaTeX adaptor for `latex-to-svg-frontend': a thin layer that tells the
shared core which regions of a LaTeX buffer are comments or verbatim (so
math inside them is not previewed), then enables the core.  All the actual
work lives in `latex-to-svg-frontend'.

It works in built-in `latex-mode' and in AUCTeX's `LaTeX-mode'.  While it
is on, AUCTeX's preview-latex commands only say that they are off: they
would draw their own images over these.

Usage:

  (add-hook 'LaTeX-mode-hook #'latex-to-svg-for-latex-mode)  ; AUCTeX
  (add-hook 'latex-mode-hook #'latex-to-svg-for-latex-mode)  ; tex-mode.el

Per-buffer settings are the core's buffer-local variables; set them in the
same hook, e.g. `(setq-local latex-to-svg-frontend-rescale-display 1.25)'.
