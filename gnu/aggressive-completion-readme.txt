Aggressive completion mode (`aggressive-completion-mode') is a minor mode
which automatically completes for you after a short delay
(`aggressive-completion-delay') and always shows all possible completions
using the standard completion help (unless the number of possible
completions exceeds `aggressive-completion-max-shown-completions').

Automatic completion is done after all commands in
`aggressive-completion-auto-complete-commands'.

Aggressive completion can be toggled using
`aggressive-completion-toggle-auto-complete' (bound to `M-t' by default)
which is especially useful when trying to find a not yet existing file or
switch to a new buffer.

You can switch from minibuffer to *Completions* buffer and back again using
`aggressive-completion-switch-to-completions' (bound to `M-c' by default).
All keys bound to this command in `aggressive-completion-minibuffer-map'
will be bound to `other-window' in `completion-list-mode-map' so that those
keys act as switch-back-and-forth commands.