`prism' disperses Lisp forms (and other syntax bounded by
parentheses, brackets, and braces) into a spectrum of color by
depth.  It's similar to `rainbow-blocks', but it respects existing
non-color face properties, and allows flexible configuration of
faces and colors.  It also optionally colorizes strings and/or
comments by code depth in a similar, customizable way.

Usage:

1.  Run the appropriate command for the current buffer:

  - For Lisp and C-like languages, use `prism-mode'.

  - For significant-whitespace languages like Python, or ones whose
    depth is not always indicated by parenthetical characters, like
    shell, use `prism-whitespace-mode' instead.

2.  Enjoy.

When a theme is loaded or disabled, colors are automatically
updated.

To customize, see the `prism' customization group, e.g. by using
"M-x customize-group RET prism RET".  For example, by default,
comments and strings are colorized according to depth, similarly to
code, but this can be disabled.

Advanced:

More advanced customization of faces is done by calling
`prism-set-colors', which can override the default settings and
perform additional color manipulations.  The primary argument is
COLORS, which should be a list of colors, each of which may be a
name, a hex RGB string, or a face name (of which the foreground
color is used).  Note that the list of colors need not be as long
as the number of faces that's actually set (e.g. the default is 16
faces), because the colors are automatically repeated and adjusted
as necessary.

If `prism-set-colors' is called with the SAVE argument, the results
are saved to customization options so that `prism-mode' will use
those colors by default.

Here's an example that the author finds pleasant:

  (prism-set-colors :num 16
    :desaturations (cl-loop for i from 0 below 16
                            collect (* i 2.5))
    :lightens (cl-loop for i from 0 below 16
                       collect (* i 2.5))
    :colors (list "sandy brown" "dodgerblue" "medium sea green")

    :comments-fn
    (lambda (color)
      (prism-blend color
        (face-attribute 'font-lock-comment-face :foreground) 0.25))

    :strings-fn
    (lambda (color)
      (prism-blend color "white" 0.5)))
