
This package allows to run django commands

Available interactive commands

`django-commands-shell'
Runs shell command in `django-commands-shell-mode'. It's derived from
`inferior-python-mode' so there are native completions and pdb tracking mode.

`django-commands-server'
Runs server command in `comint-mode' with pdb tracking mode and `compilation-shell-minor-mode'.

`django-commands-test'
Asks test name to run and then runs test command in `comint-mode' with pdb
tracking enabled and `compilation-shell-minor-mode'.

`django-commands-restart'
Being runned in one of django command buffers restarts current django command.

If command is invoked with prefix argument (for ex. C-u M-x `django-commands-shell' RET)
it allow to edit command arguments.

See README.md for more info.
