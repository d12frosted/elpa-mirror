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

Because headers have to fit within one line, sometimes the final part of the
prompt is not visible.  To ensure that the prompt's beginning and end are
always both visible, you can use `sticky-shell-shorten-header-mode'.

If you'd like this shorten-header mode to be enabled by default, you should
add `sticky-shell-shorten-header-set-mode' to `sticky-shell-mode-hook'
