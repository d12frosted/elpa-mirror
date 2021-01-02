Add support for system trash on OS X.  In other words, make
`delete-by-moving-to-trash' do what you expect it to do.

Emacs does not support the system trash of OS X.  `system-move-file-to-trash'
is not defined.  This library provides `osx-trash-move-file-to-trash' as an
implementation of `system-move-file-to-trash' for OS X.

`osx-trash-move-file-to-trash' tries to use `trash' utility from
https://github.com/ali-rantakari/trash (brew install trash).  If `trash' is
not available, the script falls back to an AppleScript helper which trashes
the file via finder.  `trash' is generally preferred, because AppleScript is
slow.

To enable, call `osx-trash-setup' and set `delete-by-moving-to-trash' to a
non-nil value.
