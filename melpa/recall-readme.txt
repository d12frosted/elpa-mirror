Recall and rerun processes created by the likes of `eshell',
`async-shell-command', `compile' and
`dired-do-async-shell-command'.

Use `recall-list' to see working directory, stdout, start time, end
time, exit code and vc revision for live and exited processes.

`recall-rerun' to rerun any process.
`recall-rerun-edit' to rerun process after editing shell command.
`recall-find-log' to open process output log file.
`recall-process-kill' to kill running process.
...

Joining the functionality of bash reverse-i-search with `proced'
(for subprocesses of Emacs).

Includes integration with `embark' and `consult'.

Enable global mode `recall-mode' to start processes monitoring.

Note:
This package uses `add-advice' on `make-process' and friends to
store metadata.  This is core Emacs functionality, usage might
have unintended consequences.  Disable `recall-mode' at the first
signs of process spawning troubles.

Package is inspired by detached.el
