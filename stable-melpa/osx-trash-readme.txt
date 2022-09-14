Add support for system trash on OS X.  In other words, make
`delete-by-moving-to-trash' do what you expect it to do.

Emacs does not support the system trash of OS X.  This library
provides `osx-trash-move-file-to-trash' as an implementation of
`system-move-file-to-trash' for OS X.

By default an AppleScript helper is used to actually trash the
file using the finder, but that is slow, so you might want to
customize option `osx-trash-command' to use a faster command.

To enable use of the system trash, call `osx-trash-setup' and
set `delete-by-moving-to-trash' to a non-nil value.
