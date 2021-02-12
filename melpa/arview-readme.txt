Arview extracts an archive file in the temporary directory and
opens a dired buffer for the directory.  Each archive has a unique
temporary directory:

`temporary-file-directory'/arview-<archive-filename>.<random-string>

Arview deletes the directory of the extracted archive when its
dired buffer is killed.

For remote archives arview copies them to
`temporary-file-directory'.  When the dired buffer of the copied
archive is killed and deleted its directory, the archive is
deleted too.

Arview is useful when archives have big directory trees and it is
inconvenient to view their content with `archive-mode'.  Or if you
want to use external programs on archived files, or copy them to
some other place, or do some sophisticated processing.

Use the command `arview' which asks for an archive file name.  In
`dired-mode' use `arview-dired' (bound to C-return by default).
When the commands called with one prefix argument, arview prompts
you for another temporary directory instead of the default one.
With two prefix arguments you can also specify additional arguments
for the archive program.

To use arview, make sure that this file is in load-path and insert
in your .emacs:

  (require 'arview)
