This package provides a minor mode that creates a header in a shell buffer.
The header shows a previous prompt according to the customizable value of
`sticky-shell-get-prompt'.
This is most useful when working with many lines of output:
you can ensure that the command corresponding to the top output-line
is always visible by setting `sticky-shell-get-prompt' to
`sticky-shell-prompt-above-visible' (its default value).
The mode can be set globally (for all shell buffers)
with `sticky-shell-global-mode'.
