This package implements the macro `##', which provides compact
syntax for short `lambda', without actually being new syntax,
which would be difficult to get merged into Emacs.  Past attempts
to add syntax were met with determined pushback and the use of a
macro was suggested as an alternative.

The `##' macro, whose signature is (## FN &rest BODY), expands
to a `lambda' expression, which wraps around these arguments.

This `lambda' expression calls the function FN with arguments
BODY and returns its value.  Its own arguments are derived from
symbols found in ARGS.

Each symbol from `%1' through `%9', which appears in BODY,
specifies an argument.  Each symbol from `&1' through `&9', which
appears in BODY, specifies an optional argument.  All arguments
following an optional argument have to be optional as well, thus
their names have to begin with `&'.  Symbol `&*' specifies extra
(`&rest') arguments.

Instead of `%1', the shorthand `%' can be used; but that should
only be done if it is the only argument, and using both `%1' and
`%' is not allowed.  Likewise `&' can be substituted for `&1'.

Instead of:

  (lambda (a _ &optional c &rest d)
    (foo a (bar c) d))

you can use this macro and write:

  (##foo %1 (bar &3) &*)

which expands to:

  (lambda (%1 &optional _&2 &3 &rest &*)
    (foo %1 (bar &3) &*))

Unused trailing arguments and mandatory unused arguments at the
border between mandatory and optional arguments are also supported:

  (##list %1 _%3 &5 _&6)

becomes:

  (lambda (%1 _%2 _%3 &optional _&4 &5 _&6)
    (list %1 &5))

Note how `_%3' and `_&6' are removed from the body, because their
names begin with an underscore.  Also note that `_&4' is optional,
unlike the explicitly specified `_%3'.

The name `##' was chosen because that allows (optionally)
omitting the whitespace between it and the following symbol.
It also looks similar to #'function.
