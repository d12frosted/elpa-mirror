Interactive prompt for key, a shell buffer name, and a sequence of
shell commands to run in that buffer.  Simply pressing <RET> at
"Command to run" will stop it for asking for more.

To set it up you bind the definer to some key, e.g:

    (global-set-key (kbd "C-c C-t") #'quick-shell-keybind)

Using this will now start the prompt sequence.

The variable 'quick-shell-keybind-default-buffer-name' can be used
customize the default buffer to something other than "*shell*".
