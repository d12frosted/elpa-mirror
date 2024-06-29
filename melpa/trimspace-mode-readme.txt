This package provides a very minimal minor mode that adds a hook to
run `delete-trailing-whitespace' before saving a file.

It also has the function `trimspace-mode-maybe', which
activates the mode only if the buffer does not already have traling
whitespace or newlines.

In addition, `require-final-newline' is enabled, since it's assumed that if
you want the editor to maintain trailing whitespace, you are most likely to
also want to maintain a trailing final newline in all files.

This package provides a minimalistic minor mode that enables Emacs' built-in
functions to trim/fix:

- whitespace trailing off ends of lines.
- multiple newlines at the end of a file.
- empty lines at the end of a file.
- missing newline at end of file.

It contains the function `trimspace-mode-maybe', which activates the mode
conditionally, only if it can not find pre-existing issues of any of these
types.

The package has functions to detect if the file has any of these issues
previously, but only uses built-in Emacs functionality to perform the
clean-up, by specifically:

- setting the variables `require-final-newline' and `delete-trailing-lines' locally.
- adding the function `delete-trailing-whitespace' to `before-save-hook'.

This package is intentionally minimalistic and only concerned with whitespace
trailing off lines and files, not other whitespace issues like multiple
spaces, erronous mixing of tabs and spaces, &c. For that you may be
interested in the package `whitespace-mode', included in Emacs.

To enable this mode for any new files opened, but only if they are already
clean of trailing whitespace and newlines, you can use this:

(add-hook 'prog-mode-hook 'trimspace-mode-maybe)
(add-hook 'text-mode-hook 'trimspace-mode-maybe)

Or something like this with `use-package':

(use-package trimspace-mode
  :hook
  (prog-mode . trimspace-mode-maybe)
  (text-mode . trimspace-mode-maybe))

If you open a file with trailing whitespace and want to clean them out, you
can enable the mode anyway with `M-x trimspace-mode', which will then make
Emacs perform clean-up the next time you save the file.
