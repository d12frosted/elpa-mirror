`eve-mode` is a major mode for editing [Eve Documents][1] built on
top of `polymode`.  Since Eve blocks (analagous to DB queries) are
conventionally embedded in markdown documents, markdown mode is
used as the host mode and code blocks are treated as executable eve
blocks. If the fenced code block has an `info string` with a value
other than "eve", the code block will be ignored.  It currently has
support for syntax highlighting and simple indentation.  Beginning
in 0.4, fenceless codeblocks are also supported via the `end`
keyword.  This is opt-in behavior via `eve-future-mode` (also
provided by this package).  Support will be added for syntax and
build error reporting once the new language service is written.

[1]: http://witheve.com/

`eve-mode` adds itself to the `auto-mode-alist` for `.eve` files
automatically.  If you'd like to use eve-mode in a document with
another extension, use `M-x eve-mode`.
