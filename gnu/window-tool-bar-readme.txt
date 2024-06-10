This package puts a tool bar in each window.  This allows you to see
multiple tool bars simultaneously directly next to the buffer it
acts on which feels much more intuitive.  Emacs "browsing" modes
generally have sensible tool bars, for example: *info*, *help*, and
*eww* have them.

It does this while being mindful of screen real estate.  If
`tool-bar-map' is nil, then this package will not take up any space
for an empty tool bar.  Most modes do not define a custom tool bar,
so calling (setq tool-bar-map nil) in your init file will make most
buffers not take up space for a tool bar.

To get the default behavior, run (global-window-tool-bar-mode 1) or
enable via M-x customize-group RET window-tool-bar RET.  This uses
the per-window tab line to show the tool bar.

If you want to share space with an existing tab line, mode line, or
header line, add (:eval (window-tool-bar-string)) to
`tab-line-format', `mode-line-format', or `header-line-format'.

For additional documentation, see info node `(emacs)Window Tool
Bar'