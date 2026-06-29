1 Llama — Compact syntax for short lambda
═════════════════════════════════════════

  This package implements a macro named `##', which provides a compact
  way to write short `lambda' expressions.

  The signature of the macro is `(## FN &rest BODY)' and it expands to a
  `lambda' expression, which calls the function `FN' with the arguments
  `BODY' and returns the value of that.  The arguments of the `lambda'
  expression are derived from symbols found in `BODY'.

  Each symbol from `%1' through `%9', which appears in an unquoted part
  of `BODY', specifies a mandatory argument.  Each symbol from `&1'
  through `&9', which appears in an unquoted part of `BODY', specifies
  an optional argument.  The symbol `&*' specifies extra (`&rest')
  arguments.

  The shorter symbol `%' can be used instead of `%1', but using both in
  the same expression is not allowed.  Likewise `&' can be used instead
  of `&1'.  These shorthands are not recognized in function position.

  To support binding forms that use a vector as `VARLIST' (such as
  `-let' from the `dash' package), argument symbols are also detected
  inside of vectors.

  The space between `##' and `FN' can be omitted because `##' is
  read-syntax for the symbol whose name is the empty string.  If you
  prefer you can place a space there anyway, and if you prefer to not
  use this somewhat magical symbol at all, you can instead use the
  alternative name `llama'.

  Instead of:

  ┌────
  │ (lambda (a &optional _ c &rest d)
  │   (foo a (bar c) d))
  └────

  you can use this macro and write:

  ┌────
  │ (##foo %1 (bar &3) &*)
  └────

  which expands to:

  ┌────
  │ (lambda (%1 &optional _&2 &3 &rest &*)
  │   (foo %1 (bar &3) &*))
  └────

  Unused trailing arguments and mandatory unused arguments at the border
  between mandatory and optional arguments are also supported:

  ┌────
  │ (##list %1 _%3 &5 _&6)
  └────

  becomes:

  ┌────
  │ (lambda (%1 _%2 _%3 &optional _&4 &5 _&6)
  │   (list %1 &5))
  └────

  Note how `_%3' and `_&6' are removed from the body, because their
  names begin with an underscore.  Also note that `_&4' is optional,
  unlike the explicitly specified `_%3'.

  Consider enabling `llama-fontify-mode' to highlight `##' and its
  special arguments.
