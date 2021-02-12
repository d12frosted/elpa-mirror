Global minor-mode to print `__git_ps1` in mode-line.

This minor-mode will print current `git` status in Emacs mode-line as a
mode-name. Status text will be generated using `__git_ps1`, which is usually
defined in `"git-prompt.sh"`. By default, the text should be like
`"[GIT:master *]"`.


User Configuration Variables
----------------------------

* `git-ps1-mode-lighter-text-format`

  Format string for `git-ps1-mode` lighter (mode-name). By default it is set
  to `" [GIT:%s]"`.

* `git-ps1-mode-ps1-file`

  File path to the script that has `__git_ps1` definition.
  When set to nil, try to find the definition automatically.

* `git-ps1-mode-showdirtystate`
* `git-ps1-mode-showstashstate`
* `git-ps1-mode-showuntrackedfiles`
* `git-ps1-mode-showupstream`

  Values for `GIT_PS1_SHOWDIRTYSTATE`, `GIT_PS1_SHOWSTASHSTATE`,
  `GIT_PS1_SHOWUNTERACKEDFILES` and `GIT_PS1_SHOWUPSTREAM` respectively.
  These variables configure output of `__git_ps1`: see document in
  "git-prompt.sh" file for details.

* `git-ps1-mode-idle-interval`

  If Emacs is idle for this seconds, this mode will update the status text.
  By default it is set to `2`.
