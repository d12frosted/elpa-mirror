This package provides the ``line-up-words'' function that tries to
align words in the region in an intelligent way.  It is similar to
the ``align-regexp'' function but is a bit more clever in the way
it align words.

Additionally, it was developed with the OCaml programming language
in mind and behaves well in OCaml source files.  More precisely it
ignores OCaml comments and tries to leave quoted strings
unmodified.

The reformatting algorithm is implemented as a separate executable,
so you will need to install it before you can use
``line-up-words''.

Installation:
You need to install the OCaml program ``line-up-words''.  The
easiest way to do so is to install the opam package manager:

  https://opam.ocaml.org/doc/Install.html

and then run "opam install line-up-words".
