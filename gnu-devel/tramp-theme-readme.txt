This is a custom theme for remote buffers.

It is not an own custom theme by itself.  Rather, it is a custom
theme to run on top of other custom themes.  It shall be loaded
always as the last custom theme, because it inherits existing
settings.

This custom theme extends `mode-line-buffer-identification' by the
name of the remote host.  It also allows to change faces according
to the value of `default-directory' of a buffer.  See
`tramp-theme-face-remapping-alist' for customization options.
