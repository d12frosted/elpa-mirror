This package provides the command `imake', which prompts for
a `make' target and runs it in the current directory.

This is an opinionated command suitable for simple Makefiles
such as those that can be found in the repositories of some
Emacs packages.  The make targets to be offered as completion
candidates have to be documented like so:

  help:
          $(info make lisp  - generate byte-code and autoloads)
          $(info make clean - remove generated files)

More precisely, a `help' target containing lines that match
the regexp "^\t$(info make \\([^)]*\\))" is expected.
