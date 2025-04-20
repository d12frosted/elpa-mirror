Inform is a compiler for adventure games by Graham Nelson,
available at https://www.inform-fiction.org/inform6.html

This file implements a major mode for editing Inform 6 programs. It
understands most Inform syntax and is capable of indenting lines
and formatting quoted strings.

Because Inform header files use the extension ".h" just as C header
files do, the function `inform-maybe-mode' is provided.  It looks at
the contents of the current buffer; if it thinks the buffer is in
Inform, it selects inform-mode; otherwise it selects the mode given
by the variable `inform-maybe-other'.

Please file bug reports at https://github.com/rrthomas/inform-mode
