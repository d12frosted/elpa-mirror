This package puts a tool bar in each window.  This allows you to see
multiple tool bars simultaneously directly next to the buffer it
acts on which feels much more intuitive.  Emacs "browsing" modes
generally have sensible tool bars, for example: *info*, *help*, and
*eww* have them.

It does this while being mindful of screen real estate.  Most modes
do not provide a custom tool bar, and this package does not show the
default tool bar.  This means that for most buffers there will be no
space taken up.  Furthermore, you can put this tool bar in the mode
line or tab line if you want to share it with existing content.

To get the default behavior, run (global-window-tool-bar-mode 1) or
enable via M-x customize-group RET window-tool-bar RET.  This uses
the per-window tab line to show the tool bar.

If you want to share space with an existing tab line, mode line, or
header line, add (:eval (window-tool-bar-string)) to
`tab-line-format', `mode-line-format', or `header-line-format'.