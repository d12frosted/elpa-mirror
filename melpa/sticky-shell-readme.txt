This package provides a minor mode that creates a header in a shell buffer.
The header shows a previous prompt according to the customizable value of
`sticky-shell-get-prompt'.

This is most useful when working with many lines of output:
you can ensure that the command corresponding to the top output-line
is always visible by setting `sticky-shell-get-prompt' to
`sticky-shell-prompt-above-visible' (its default value).

To enable the mode, run `sticky-shell-mode' in any shell buffer.

To enable the mode globally (for all shell buffers)
run `sticky-shell-global-mode'.

`sticky-shell-mode' currently supports any mode derived from the following:
`shell-mode', `eshell-mode', `term-mode', `vterm-mode'.
It should be easy to add support for additional modes:
see `sticky-shell-supported-modes'.

Because headers have to fit within one line, sometimes the final part of the
prompt is not visible.  To ensure that the prompt's beginning and end are
always both visible, you can use `sticky-shell-shorten-header-mode'.

If you'd like this shorten-header mode to be enabled by default, you should
add `sticky-shell-shorten-header-set-mode' to `sticky-shell-mode-hook'

Note that `sticky-shell-shorten-header-mode' doesn't work properly in
`term-mode' and `vterm-mode'. This is not because of an issue with
`sticky-shell-shorten-header-mode' itself, but because `sticky-shell-mode'
uses `(thing-at-point 'line)' to read a prompt: in terminal modes, this
function returns a line within the borders of a window rather than up to the
first newline character. The result is that the header will always be cut-off
at the window-border.
Right now I'd rather keep this general implementation simple rather than
overfit for these particular modes.
You can always define your own `sticky-shell-get-prompt' function that works
as desired: if this function returns a string that doesn't fit fully within
one line, `sticky-shell-shorten-header-mode' would work as usual.
