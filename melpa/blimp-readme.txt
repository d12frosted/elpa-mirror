This package is a complete wrapper around all imagemagick commands
with descriptions, autocompletion (for some commands) and hints
displayed in prompt using eimp.el to execute its commands and
resize images.

Switch the blimp minor mode on programmatically with:

    (blimp-mode 1)

or toggle interactively with M-x blimp-mode RET.

Switch the minor mode on for all image-mode buffers with:

    (add-hook 'image-mode-hook 'blimp-mode)

Then once blimp-mode is enabled, do `M-x blimp-interface'
to to add commands to be executed on the image.

The added commands can be executed with `M-x blimp-execute-command-stack'
and cleared with `M-x blimp-clear-command-stack'.

If you want to execute the command right after selecting it
you can do `M-x blimp-interface-execute'.

The prefix of the command can also be changed
with `M-x blimp-toggle-prefix'.
