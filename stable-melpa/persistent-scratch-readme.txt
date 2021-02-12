Preserve the state of scratch buffers across Emacs sessions by saving the
state to and restoring it from a file, with autosaving and backups.

Save scratch buffers: `persistent-scratch-save' and
`persistent-scratch-save-to-file'.
Restore saved state: `persistent-scratch-restore' and
`persistent-scratch-restore-from-file'.

To control where the state is saved, set `persistent-scratch-save-file'.
What exactly is saved is determined by `persistent-scratch-what-to-save'.
What buffers are considered scratch buffers is determined by
`persistent-scratch-scratch-buffer-p-function'. By default, only the
`*scratch*' buffer is a scratch buffer.

Autosave can be enabled by turning `persistent-scratch-autosave-mode' on.

Backups of old saved states are off by default, set
`persistent-scratch-backup-directory' to a directory to enable them.

To both enable autosave and restore the last saved state on Emacs start, add
  (persistent-scratch-setup-default)
to the init file. This will NOT error when the save file doesn't exist.

To just restore on Emacs start, it's a good idea to call
`persistent-scratch-restore' inside an `ignore-errors' or
`with-demoted-errors' block.
