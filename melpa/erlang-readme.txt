Introduction:
------------

This package provides support for the programming language Erlang.
The package provides an editing mode with lots of bells and
whistles, compilation support, and it makes it possible for the
user to start Erlang shells that run inside Emacs.

See the Erlang distribution for full documentation of this package.

Installation:
------------

Place this file in Emacs load path, byte-compile it, and add the
following line to the appropriate init file:

   (require 'erlang-start)

The full documentation contains much more extensive description of
the installation procedure.

Reporting Bugs:
--------------

Please send bug reports to the following email address:
     erlang-bugs@erlang.org
or if you have a patch suggestion to:
     erlang-patches@erlang.org
Please state as exactly as possible:
   - Version number of Erlang Mode (see the menu), Emacs, Erlang,
     and of any other relevant software.
   - What the expected result was.
   - What you did, preferably in a repeatable step-by-step form.
   - A description of the unexpected result.
   - Relevant pieces of Erlang code causing the problem.
   - Personal Emacs customisations, if any.

Should the Emacs generate an error, please set the Emacs variable
`debug-on-error' to `t'.  Repeat the error and enclose the debug
information in your bug-report.

To toggle the variable you can use the following command:
    M-x toggle-debug-on-error RET
