
Virtual Auto Fill mode displays unfilled text in a readable way.  It wraps
the text as if you had inserted line breaks (e.g. using `fill-paragraph' or
`auto-fill-mode') without actually modifying the underlying buffer.  It also
indents paragraphs in bullet lists properly.

Specifically, `adaptive-wrap-prefix-mode', Visual Fill Column mode and
`visual-line-mode' are used to wrap paragraphs and bullet lists between the
wrap prefix and the fill column.
