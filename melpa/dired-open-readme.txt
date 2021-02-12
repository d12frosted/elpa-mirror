While emacs already has the `auto-mode-alist', this is often
insufficient.  Many times, you want to open media files, pdfs or
other documents with an external application.  There's remedy for
that too, namely `dired-guess-shell-alist-user', but that is still
not as convenient as just hitting enter.

This package adds a mechanism to add "hooks" to `dired-find-file'
that will run before emacs tries its own mechanisms to open the
file, thus enabling you to launch other application or code and
suspend the default behaviour.

By default, two additional methods are enabled,
`dired-open-by-extension' and `dired-open-subdir'.

This package also provides other convenient hooks:

* `dired-open-xdg' - try to open the file using `xdg-open'
* `dired-open-guess-shell-alist' - try to open the file by
  launching applications from `dired-guess-shell-alist-user'
* `dired-open-call-function-by-extension' - call an elisp function
  based on extension.

These are not used by default.

You can customize the list of functions to try by customizing
`dired-open-functions'.

To fall back to the default `dired-find-file', you can provide the
prefix argument (usually C-u) to the `dired-open-file' function.
This is useful for example when you configure html files to be
opened in browser and you want to edit the file instead of view it.

Note also that this package can handle calls when point is not on a
line representing a file---an example hook is provided to open a
subdirectory under point if point is on the subdir line, see
`dired-open-subdir'.

If you write your own handler, make sure they do *not* throw errors
but instead return nil if they can't proceed.

See https://github.com/Fuco1/dired-hacks for the entire collection.
