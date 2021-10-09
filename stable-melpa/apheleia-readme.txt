Apheleia is an Emacs Lisp package which allows you to reformat a
buffer without moving point. This solves the usual problem of
running a tool like Prettier or Black on `before-save-hook', namely
that it resets point to the beginning of the buffer. Apheleia
maintains the position of point relative to its surrounding text
even if the buffer is modified by the reformatting.

Please see https://github.com/raxod502/apheleia for more information.
