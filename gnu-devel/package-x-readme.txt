This file currently contains parts of the package system that many
won't need, such as package uploading.

To upload to an archive, first set `package-archive-upload-base' to
some desired directory.  For testing purposes, you can specify any
directory you want, but if you want the archive to be accessible to
others via http, this is typically a directory in the /var/www tree
(possibly one on a remote machine, accessed via Tramp).

Then call M-x package-upload-file, which prompts for a file to
upload.  Alternatively, M-x package-upload-buffer uploads the
current buffer, if it's visiting a package file.

Once a package is uploaded, users can access it via the Package
Menu, by adding the archive to `package-archives'.