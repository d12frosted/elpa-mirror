
dired-fdclone.el provides the following interactive commands:

* diredfd-goto-top
* diredfd-goto-bottom
* diredfd-toggle-mark-here
* diredfd-toggle-mark
* diredfd-toggle-all-marks
* diredfd-mark-or-unmark-all
* diredfd-narrow-to-marked-files
* diredfd-narrow-to-files-regexp
* diredfd-goto-filename
* diredfd-do-shell-command
* diredfd-do-sort
* diredfd-do-flagged-delete-or-execute
* diredfd-enter
* diredfd-enter-directory
* diredfd-enter-parent-directory
* diredfd-enter-root-directory
* diredfd-history-backward
* diredfd-history-forward
* diredfd-follow-symlink
* diredfd-do-pack
* diredfd-do-unpack
* diredfd-help
* diredfd-nav-mode

The above functions are mostly usable stand-alone, but if you feel
like "omakase", add the following line to your setup.

  (dired-fdclone)

This makes dired:

- color directories in cyan and symlinks in yellow like FDclone
- sort directory listings in the directory-first style
- alter key bindings to mimic FD/FDclone
- not open a new buffer when you navigate to a new directory
- run a shell command in ansi-term to allow launching interactive
  commands
- automatically revert the buffer after running a command with
  obvious side-effects
- automatically add visited files to `file-name-history`
  (customizable)

Without spoiling dired's existing features.

As usual, customization is available via:

  M-x customize-group dired-fdclone RET
