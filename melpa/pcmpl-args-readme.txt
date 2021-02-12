
This package extends option and argument completion of shell
commands read by Emacs.  It is intended to make shell completion in
Emacs comparable to the rather excellent completion provided by
both Bash and Zsh.

This package uses `pcomplete' to define completion handlers which
are used whenever shell completion is performed.  This includes
when commands are read in the minibuffer via `shell-command' (M-!)
or in `shell-mode'.

Completion support is provided for many different commands
including:

  - GNU core utilities (ls, rm, mv, date, sort, cut, printf, ...)

  - Built-in shell commands (if, test, time, ...)

  - Various GNU/Linux commands (find, xargs, grep, man, tar, ...)

  - Version control systems (bzr, git, hg, ...)


Installation:

To use this package, save `pcmpl-args.el' to your `load-path' and
add the following to your `init.el':

    (require 'pcmpl-args)

Note: This package uses `lexical-binding' so it probably will not
work with older versions of Emacs (prior to 24.1).

Note: This package redefines the following functions:

  `pcomplete/bzip2'
  `pcomplete/chgrp'
  `pcomplete/chown'
  `pcomplete/gdb'
  `pcomplete/gzip'
  `pcomplete/make'
  `pcomplete/rm'
  `pcomplete/rmdir'
  `pcomplete/tar'
  `pcomplete/time'
  `pcomplete/which'
  `pcomplete/xargs'


Defining new completion commands:

This package contains a number of utilities for defining new
pcomplete completion commands:

`pcmpl-args-pcomplete'
     Can be used to define completion for commands that have
     complex option and argument parsing.

`pcmpl-args-pcomplete-on-help'
     Completion via parsing the output of `COMMAND --help'.

`pcmpl-args-pcomplete-on-man'
     Completion via parsing the output of `man COMMAND'.
