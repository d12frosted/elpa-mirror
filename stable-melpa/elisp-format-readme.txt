
This package is format elisp code.
This package is format by itself, so you can view format effect.

Below are commands you can use:

`elisp-format-region'
     Format region or defun.
`elisp-format-buffer'
     Format buffer.
`elisp-format-file'
     Format file.
`elisp-format-file-batch'
     Format file with `batch'.
`elisp-format-directory'
     Format recursive elisp files in directory.
`elisp-format-directory-batch'
     Format recursive elisp files in directory with `batch'.
`elisp-format-dired-mark-files'
     Format dired marked files.
`elisp-format-library'
     Format library.

Tips:

If current mark is active, command `elisp-format-region'
will format region you select, otherwise it will format
`defun' around point.

If you want format many files, you can marked them in dired,
and use command `elisp-format-dired-mark-files' to format
marked files in dired.

You can format special file through
command `elisp-format-file'.

By default, when you format `huge' file, it will
hang emacs.
You can also use command `elisp-format-file-batch'
make format process at background.

You also can use command `elisp-format-directory'
format all recursive elisp files in special directory.

By default, when you use command `elisp-format-directory'
format too many elisp files, will hang emacs.
You can also use command `elisp-format-directory-batch'
make format process at background.

If you're sure lazy, you can use command `elisp-format-library'
format special library and don't need input long file path.

Note:

I can't ensure this package can perfect work with all situations.
So please let me know if you have suggestion or bug.


; Installation:

Put elisp-format.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name "~/elisp"))

And the following to your ~/.emacs startup file.

(require 'elisp-format)

No need more.
