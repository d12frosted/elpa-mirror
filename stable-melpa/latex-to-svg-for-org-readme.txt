
Org adaptor for `latex-to-svg-frontend': a thin layer that tells the shared
core which Org regions are code / verbatim / comment (so math inside them is
not previewed) and how to unfold a jump target (`org-fold-show-context'),
then enables the core.  All the actual work lives in
`latex-to-svg-frontend'.

Detection uses the core's universal scanner (not `org-element'); the Org
block/comment regions below are excluded from it, as are inline `~code~' /
`=verbatim=' spans, so `=\(=' stays literal text.  Disable a delimiter
family with the core toggles if a markup character still causes false
positives.

Usage:

  (add-hook 'org-mode-hook #'latex-to-svg-for-org-mode)

Per-buffer settings are the core's buffer-local variables; set them in the
same hook, e.g. `(setq-local latex-to-svg-frontend-display-rescale 1.25)'.
