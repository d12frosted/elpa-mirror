
dired-rsync is a command that can be run from a dired buffer to
copy files using rsync rather than tramps in-built mechanism.
This is especially useful for copying large files to/from remote
locations without locking up tramp.

To use simply open a dired buffer, mark some files and invoke
dired-rsync.  After being prompted for a location to copy to an
inferior rsync process will be spawned.

Wherever the files are selected from the rsync will always run from
your local machine.
