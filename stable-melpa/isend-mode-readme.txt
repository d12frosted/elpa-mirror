`isend-mode' is an Emacs extension allowing interaction with code
interpreters in `ansi-term' or `term' buffers. Some language-specific
modes (e.g. `python-mode') already provide similar features; `isend-mode'
does the same in a language-agnostic way.


Basic usage:

1. Open an `ansi-term' buffer where the interpreter will live.
   For example:

     M-x ansi-term RET /bin/sh RET

2. Open a buffer with the code you want to execute, and associate it
   to the interpreter buffer using the `isend-associate' command (also
   aliased to `isend'). For example:

     M-x isend-associate RET *ansi-term* RET

3. Press C-RET (or M-x `isend-send') to send the current line to the
   interpreter. If the region is active, all lines spanned by the region
   will be sent (i.e. no line will be only partially sent). Point is
   then moved to the next non-empty line (but see configuration variable
   `isend-skip-empty-lines').


Contributing:

If you make improvements to this code or have suggestions, please do not
hesitate to fork the repository or submit bug reports on github. The
repository is at:

    https://github.com/ffevotte/isend-mode.el
