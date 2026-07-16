
`dired-rsync' is a command that can be run from a Dired buffer to
copy files using rsync rather than TRAMP's built-in mechanism.  This
is especially useful for copying large files to/from remote locations
without locking up TRAMP.

To use simply open a Dired buffer, mark some files and invoke
`dired-rsync'.  After being prompted for a location to copy to, an
inferior rsync process will be spawned.

Wherever the files are selected from, the rsync will always run from
your local machine.

To display the progress of a running rsync process in the mode line, you can
use something like the following in your init file:

(add-to-list 'mode-line-modes
             '(dired-rsync-modeline-status dired-rsync-modeline-status))
