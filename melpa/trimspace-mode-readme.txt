This package provides a very minimal minor mode that adds a hook to
run `delete-trailing-whitespace' before saving a file.

It also has the function `trimspace-mode-unless-trailing-whitespace', which
activates the mode only if the buffer does not already have traling
whitespace or newlines.

In addition, `require-final-newline' is enabled, since it's assumed that if
you want the editor to maintain trailing whitespace, you are most likely to
also want to maintain a trailing final newline in all files.
