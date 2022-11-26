This package implements the macro `##', which provides compact
syntax for short `lambda', without actually being new syntax,
which would be difficult to get merged into Emacs.  Past attempts
to add syntax were met with determined pushback and the use of a
macro was suggested as an alternative.

The `##' macro, whose signature is (## FN &rest args), expands
to a `lambda' expressions, which wraps around its arguments.

This `lambda' expression calls the function FN with arguments
ARGS and returns its value.  Its own arguments are derived from
symbols found in ARGS.  Each symbol from `%1' through `%9', which
appears in ARGS, is treated as a positional argument.  Missing
arguments are named `_%N', which keeps the byte-compiler quiet.
In place of `%1' the shorthand `%' can be used, but only one of
these two can appear in ARGS.  `%*' represents extra `&rest'
arguments.

Instead of:

  (lambda (a _ c &rest d)
    (foo a (bar c) d))

you can use this macro and write:

  (##foo % (bar %3) %*)

which expands to:

  (lambda (% _%2 %3 &rest %*)
    (foo % (bar %3) %*))

The name `##' was choosen because that allows (optionally)
omitting the whitespace between it and the following symbol.
It also looks similar to #'function.
