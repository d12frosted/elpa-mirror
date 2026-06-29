           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            `GNU-INDENT' - INDENT YOUR CODE WITH GNU INDENT
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Keeping code correctly indented can be tedious.  And when the project is
large, maintaining a consistent style everywhere by hand can become
almost impossible.  `gnu-indent' solves this problem by doing the job
itself.  Enable `gnu-indent-mode' and continue with the your editing;
your file will be reindented by [GNU Indent] just before saving it
maintaining the position of point.

GNU Indent supports C, C++ is also partially supported.


[GNU Indent] <https://gnu.org/software/indent>


1 Installation
══════════════

1.1 Package
───────────

  Add MELPA to `package-archives' then `M-x package-install RET
  gnu-indent'.


1.2 Quelpa
──────────

  Do `M-x quelpa RET gnu-indent', Quelpa should get the recipe from
  MELPA and install it.


1.3 Straight.el
───────────────

  Put this in `(straight-use-package 'gnu-indent)' your init file,
  Straight.el should get the recipe from MELPA and install it.


2 Commands
══════════

  `gnu-indent-mode'
        Toggle auto reindentation on save.
  `gnu-indent-buffer'
        Reindent current buffer.
  `gnu-indent-region'
        Reindent current region.


3 User options
══════════════

  `gnu-indent-program'
        Name of GNU Indent program (default `"indent"').
  `gnu-indent-options'
        Arguments to pass to GNU Indent (default `nil').  You'd probably
        want to set it as a file local variable.  See GNU Indent manual
        (`C-h i m Indent RET' on Emacs, `info indent' on shell) for
        available options.
