`(require 'find-dupes-dired)` and Run `find-dupes-dired`.
With prefix argument, find dupes in multiple directories.

If needed, set `find-dupes-dired-verbose' to t for debug message.

It needs "jdupes" in Windows and "fdupes" in other system, or others by setting
`find-dupes-dired-program` and `find-dupes-dired-ls-option`.

Thanks [fd-dired](https://github.com/yqrashawn/fd-dired/blob/master/fd-dired.el)
and [rg](https://github.com/dajva/rg.el). I got some references from them.
