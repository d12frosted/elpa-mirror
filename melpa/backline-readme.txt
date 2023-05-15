An outline heading does not extend to the right edge of the window
when its body is collapsed.  This is unfortunate when the used face
sets the background color or another property that is visible on
whitespace.  This package adds overlays to extend the appearance of
headings all the way to the right window edge.

  (use-package backline
    :after outline
    :config (advice-add 'outline-flag-region :after 'backline-update))

This package should be used together with the `outline-minor-faces'
package.  Instead setting the built-in `outline-minor-mode-highlight' to
`append' also works, but then top-level s-expressions are highlighted as
if they were sections, which makes the overview less readable.
