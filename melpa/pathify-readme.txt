This file provides some code for convenient symlinking files into
particular directory (`pathify-directory').  It is intended to be
used for symlinking your scripts (or other executable files) into
your "~/bin" directory (as you surely have it in your PATH
environment variable :-).

To install the package manually, add the following to your init file:

  (add-to-list 'load-path "/path/to/pathify-dir")
  (autoload 'pathify "pathify" nil t)
  (autoload 'pathify-dired "pathify" nil t)

Optionally, set `pathify-directory' variable (if you do not use
"~/bin"):

Now you may use "M-x pathify-dired" command in a dired buffer to
pathify the marked files (or the current file if nothing is marked).
For more convenience, you may bind this command to some key, for
example:

  (eval-after-load 'dired
    '(define-key dired-mode-map "P" 'pathify-dired))
