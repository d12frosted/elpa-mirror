	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	    `GNU-INDENT' - INDENT YOUR CODE WITH GNU INDENT
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Commands
2. User options


Keeping code correctly indented can be tedious.  And when the project is
large, maintaining a consistent style everywhere by hand can become
almost impossible.  `gnu-indent' solves this problem by doing the job
itself.  Enable `gnu-indent-mode' and continue with the your editing;
your file will be reindented by [GNU Indent] just before saving it
maintaining the position of point.

GNU Indent supports C, C++ is also partially supported.


[GNU Indent] <https://gnu.org/software/indent>


1 Commands
══════════

  `gnu-indent-mode'
        Toggle auto reindentation on save.
  `gnu-indent-buffer'
        Reindent current buffer.
  `gnu-indent-region'
        Reindent current region.


2 User options
══════════════

  `gnu-indent-program'
        Name of GNU Indent program (default `"indent"').
  `gnu-indent-options'
        Arguments to pass to GNU Indent (default `nil').  See GNU Indent
        manual (`C-h i m Indent RET' on Emacs, `info indent' on shell)
        for available options.
