This package provides four major features: unkillable scratch
buffers, persistent scratch buffers, per-major-mode scratch
buffers, and per-project scratch buffers.  Although a number of
packages provide these individually, I have found them difficult to
get to play well together.  This package is designed to simplify
their use instead.

To enable the features, the major mode `scratch-plus-mode' must be
enabled.  I recommend enabling it as part of your
`after-init-hook', as follows:

    (add-hook 'after-init-hook #'scratch-plus-mode)

The different features must also be configured.

To configure persistence, the `scratch-plus-save-directory'
variable must be set to a directory.  It will be created as-needed.
To allow persistence of per-project scratch buffers, the
`scratch-plus-project-subdir' variable must be set to a string,
which will be used to compute a directory local to the project; it
will also be created as needed.  Scratch buffers will have
`save-buffer' remapped, so that they will be stored appropriately
for restoration.  Additionally, scratch buffers can be saved with
an idle timer, this is configured using `scratch-plus-idle-save',
which is nil by default.

Load-time restoration of scratch buffers is configured with two
variables, `scratch-plus-restore-type' and
`scratch-plus-force-restore'.  They behave as follows.  Consider
the pair made from (scratch-plus-restore-type
. scratch-plus-force-restore).

 - (nil . any) : no restoration is completed
 - (demand . initial) : the initially-created scratch buffer is
   killed, and only it is restored
 - (t . initial) : The initially-created scratch buffer is killed;
   all are restored.
 - (demand . t) : All detected scratch buffers are killed, and only
   the initial buffer is restored.
 - (t . t) : All detected scratch buffers are killed, and all are
   restored.

Further configuration of note is the variable
`scratch-plus-initial-message', which provides the message for
brand new (unrestored) scratch buffers.  This can be a string,
which will be used directly, or a function which takes the name of
the major mode and returns a string.  In either case, the value
will be filtered through `substitute-command-keys', and then turned
into a mode-specific comment.

Finally, jumping to a scratch buffer is also configured by
`scratch-plus-display-action', which should be a valid action for
`display-buffer', or nil to use `display-buffer-action-alist'.

;; Errors and Patches

If you find an error, or have a patch to improve this package,
please send an email to ~swflint/emacs-utilities@lists.sr.ht.
