1 Cond-Let — Additional and improved binding conditionals
═════════════════════════════════════════════════════════

  *This is an ALPHA release!* Breaking changes are possible!*

  Emacs provides the binding conditionals `if-let', `if-let*',
  `when-let', `when-let*', `and-let*' and `while-let'.

  This package implements the missing `and-let' and `while-let*', and
  the original `cond-let', `cond-let*', `and$' and `and>'.

  This package additionally provides more consistent and improved
  implementations of the binding conditionals already provided by Emacs.
  Merely loading this library does not shadow the built-in
  implementations; this can optionally be done in the context of an
  individual library, as described below.

  `cond-let' and `cond-let*' are provided exactly under these names.
  The names of all other macros implemented by this package begin with
  `cond-let--', the package's prefix for private symbol.

  Users of this package are not expected to use these unwieldy names.
  Instead one should use Emacs' shorthand feature to use all or some of
  these macros by their conceptual names.

  Please see the library header for usage information and the docstrings
  for information about the individual macros.  See also
  <https://github.com/tarsius/cond-let/wiki>.
