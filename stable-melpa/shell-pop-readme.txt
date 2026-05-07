
The shell-pop package provides on-demand access to a terminal through a
single, configurable key binding.

The package supports multiple terminal implementations, including term,
`eshell', `ansi-term', `vterm', and `eat', and ensures your original window
configuration is restored when the terminal is hidden.

Configuration:
--------------
Use M-x customize-variable RET `shell-pop-shell-type' RET to customize the
shell to use. Six pre-set options are: `shell', `terminal', `ansi-term',
`eshell', `vterm', and `eat'. You can also set your custom shell if you use
other configuration.

For `terminal' and `ansi-term' options, you can set the underlying shell by
customizing `shell-pop-term-shell'. By default, `shell-file-name' is used.

Use M-x customize-group RET shell-pop RET to set further options such as
hotkey, window height and position.
