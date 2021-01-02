
This is a utility which helps you pop up and pop out shell buffer
window easily.  Just do M-x shell-pop, and it is strongly recommended
to assign one hot-key to this function.

I hope this is useful for you, and ENJOY YOUR HAPPY HACKING!

; Configuration:

Use M-x customize-variable RET `shell-pop-shell-type' RET to
customize the shell to use.  Four pre-set options are: `shell',
`terminal', `ansi-term', and `eshell'.  You can also set your
custom shell if you use other configuration.

For `terminal' and `ansi-term' options, you can set the underlying
shell by customizing `shell-pop-term-shell'.  By default,
`shell-file-name' is used.

Use M-x customize-group RET shell-pop RET to set further options
such as hotkey, window height and position.
