1 Cond-Let — Additional and improved binding conditionals
═════════════════════════════════════════════════════════

  Emacs provides the binding conditionals `if-let', `if-let*',
  `when-let', `when-let*', `and-let*' and `while-let'.

  This package implements the missing `and-let' and `while-let*'; and
  the original `cond-let', `cond-let*', `when$', `and$', and `thread$'.

  This package additionally provides more consistent and improved
  implementations of the binding conditionals already provided by Emacs.
  Merely loading this library does not shadow the built-in
  implementations; this can optionally be done in the context of an
  individual library.

  `cond-let' and `cond-let*' are provided exactly under these names.
  The names of all other macros implemented by this package begin with
  `cond-let--', the package's prefix for private symbol.

  Users of this package are not expected to use these unwieldy names.
  Instead one should use Emacs' shorthand feature to use all or some of
  these macros by their conceptual names.

  The [library header] explains how to use shorthands and how to teach
  font-lock about these forms.  See their docstrings for information
  about the individual macros.  Visit the [wiki] for additional
  information.


[library header]
<https://github.com/tarsius/cond-let/blob/main/cond-let.el#L30>

[wiki] <https://github.com/tarsius/cond-let/wiki>
