This package implements useful features present in the
[ranger](http://ranger.github.io/) file manager which are missing
in dired.

Multi-stage copy/pasting of files
---------------------------------

A feature present in most orthodox file managers is a "two-stage"
copy/paste process.  Roughly, the user first selects some files,
"copies" them into a clipboard and then pastes them to the target
location.  This workflow is missing in dired.

In dired, user first marks the files, then issues the
`dired-do-copy' command which prompts for the destination.  The
files are then copied there.  The `dired-dwim-target' option makes
this a bit friendlier---if two dired windows are opened, the other
one is automatically the default target.

With the multi-stage operations, you can gather files from
*multiple* dired buffers into a single "clipboard", then copy or
move all of them to the target location.  Another huge advantage is
that if the target dired buffer is already opened, switching to it
via ido or ibuffer is often faster than selecting the path.

Call `dired-ranger-copy' to add marked files (or the file under
point if no files are marked) to the "clipboard".  With non-nil
prefix argument, add the marked files to the current clipboard.

Past clipboards are stored in `dired-ranger-copy-ring' so you can
repeat the past pastes.

Call `dired-ranger-paste' or `dired-ranger-move' to copy or move
the files in the current clipboard to the current dired buffer.
With raw prefix argument (usually C-u), the clipboard is not
cleared, so you can repeat the copy operation in another dired
buffer.

The copy or move operation is asynchronous if `dired-async-mode'
is activated.

Bookmarks
---------

Use `dired-ranger-bookmark' to bookmark current dired buffer.  You
can later quickly revisit it by calling
`dired-ranger-bookmark-visit'.

A bookmark name is any single character, letter, digit or a symbol.

A special bookmark with name `dired-ranger-bookmark-LRU' represents
the least recently used dired buffer.  Its default value is `.  If
you bind `dired-ranger-bookmark-visit' to the same keybinding,
hitting `` will instantly bring you to the previously used dired
buffer.  This can be used to toggle between two dired buffers in a
very fast way.

These bookmarks are not persistent.  If you want persistent
bookmarks use the bookmarks provided by emacs, see (info "(emacs)
Bookmarks").
