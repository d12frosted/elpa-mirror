An outline heading does not extend to the right edge of the window
when its body is collapsed.  This is unfortunate when the used face
sets the background color or another property that is visible on
whitespace.  This package adds overlays to extend the appearance of
headings all the way to the right window edge.

Unlike `outline-mode', `outline-minor-mode' by itself does not
highlight headings.  The `outline-minor-faces' package implements
that and is required by this package.

Usage:

  (use-package backline
    :after outline
    :config (advice-add 'outline-flag-region :after 'backline-update))
