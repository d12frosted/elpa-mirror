An outline heading does not extend to the right edge of the window
when its body is collapsed.  This is unfortunate when the used face
sets the background color or another property that is visible on
whitespace.  This package adds overlays to extend the appearance of
headings all the way to the right window edge.

  (use-package backline
    :after outline
    :config (advice-add 'outline-flag-region :after 'backline-update))

The above advice requires that `outline-minor-faces-mode' (from the
`outline-minor-faces' package) is enabled.

  (use-package outline-minor-faces
    :after outline
    :config (add-hook 'outline-minor-mode-hook
                      #'outline-minor-faces-mode))

Do NOT set `outline-minor-mode-highlight' (provided by `outline' since
Emacs 28.1) to a non-nil value, because that is incompatible with this
package and `outline-minor-faces' (which is an older and still superior
alternative).  See `outline-minor-faces' for details.
