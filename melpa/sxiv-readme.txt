The main (and only) command is `M-x sxiv`.

If it is run in a Dired buffer containing images, files marked in
sxiv (mark/unmark with `m`) will be marked in Dired. If the Dired
buffer has marked files, open only those files. With prefix
argument, or when only provided directories, run recursively.

It can also be run from a text file containing one file name per
line.

`sxiv-filter' is the process filter, to insert subdirectories (via
`sxiv-insert-subdirs') and mark files marked in sxiv (via
`sxiv-dired-mark-files').
