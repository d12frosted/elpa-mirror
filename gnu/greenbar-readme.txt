For us old neck beards, who learned to write software on punch
cards and print out our code and output on wide line printers, it
was helpful to have alternating bands of subtle background coloring
to guide our eyes across the line on the page.  Reading long rows
of text across a 14 7/8" page, it was very easy to loose your place
vertically while scanning the page horizontally.  The subtle
background shading was often done with pale bands of green
alternating with the white of the paper.

Paper pre-printed with the pale green bars was often referred to as
"green bar" and the technique is also referred to as "zebra
striping."  In Emacs, in `ps-print.el' (PostScript print facility),
the feature is enabling with the `ps-zebra-stripes' setting.

To enable `greenbar-mode' in your `comint-mode' buffers, add the
following to your Emacs configuration:

    (add-hook 'comint-mode-hook #'greenbar-mode)

If you want to enable `greenbar-mode' only in a single mode derived
from `comint-mode', then you need to add `greenbar-mode' only to
the desired derived mode hook.  Adding `greenbar-mode' to
`comint-mode-hook' enables it for all comint derived modes.

The variable `greenbar-color-theme' is an Alist of predefined bar
background colors.  Each element of the Alist consists of a symbol
that is the name of the theme; the rest of the list are color names
which are used as background colors for successive bands of lines.

The variable `greenbar-color-list' controls which set of color bars
are to be applied.  The value is either a name from color theme
defined in `greenbar-color-themes' or it is a list of color names.

The variable `greenbar-lines-per-bar' controls how many output
lines are displayed using each band's background color.

By default, input lines are not highlighted, but if
`greenbar-highlight-input' is set to a non-nil value, then input is
also highlighted with green bars as well.

Suggestions for other background color themes are always welcome.