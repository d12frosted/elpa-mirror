This package provides the command `imake', which prompts for
make targets and runs them in the current directory.

If the `marginalia' package is available and some targets are
documented as shown below, using one or more targets whose
names begin with "help", then that documentation is shown.

  help helpall::
          $(info make lisp  - generate byte-code and autoloads)
  helpall::
          $(info make clean - remove generated files)
