This package provides the M-x vlf command, which visits part of
large file without loading it entirely.  The buffer uses VLF mode,
which provides several commands for moving around, searching,
comparing and editing selected part of file.
To have it offered when opening large files:
(require 'vlf-setup)

This package was inspired by a snippet posted by Kevin Rodgers,
showing how to use `insert-file-contents' to extract part of a
file.
