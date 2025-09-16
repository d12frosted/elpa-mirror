This is an ALPHA release!
Breaking changes are possible!

Emacs provides the binding conditionals `if-let', `if-let*',
`when-let', `when-let*', `and-let*' and `while-let'.

This package implements the missing `and-let' and `while-let*',
and the original `cond-let', `cond-let*', `and$' and `and>'.

This package additionally provides more consistent and improved
implementations of the binding conditionals already provided by
Emacs.  Merely loading this library does not shawow the built-in
implementations; this can optionally be done in the context of
an individual library, as described below.

`cond-let' and `cond-let*' are provided exactly under these names.
The names of all other macros implemented by this package begin
with `cond-let--', the package's prefix for private symbol.

Users of this package are not expected to use these unwieldy
names.  Instead one should use Emacs' shorthand feature to use
all or some of these macros by their conceptual names.  E.g., if
you want to use all of the available macros, add this at the end
of a library.

Local Variables:
read-symbol-shorthands: (
  ("and$"      . "cond-let--and$")
  ("and>"      . "cond-let--and>")
  ("and-let"   . "cond-let--and-let")
  ("if-let"    . "cond-let--if-let")
  ("when-let"  . "cond-let--when-let")
  ("while-let" . "cond-let--while-let"))
End:

You can think of these file-local settings as import statements of
sorts.  If you do this, then this package's implementations shadow
the built-in implementations.  Doing so does not affect any other
libraries, which continue to use the built-in implementations.

Due to limitations of the shorthand implementation this has to be
done for each individual library.  "dir-locals.el" cannot be used.

If you use `and$' and `and>', you might want to add this to your
configuration:

  (with-eval-after-load 'cond-let
    (font-lock-add-keywords 'emacs-lisp-mode
                            cond-let-font-lock-keywords t))

For information about the individual macros, please refer to their
docstrings.

See also https://github.com/tarsius/cond-let/wiki.
