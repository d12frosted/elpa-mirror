This is XML/XHTML done with S-Expressions in EmacsLisp.  Simply,
this is the easiest way to write HTML or XML in Lisp.

This library uses the native form of XML representation as used by
many libraries already included within emacs.  This representation
will be referred to as "esxml" throughout this library.  See
`esxml-to-xml' for a concise description of the format.

This library is not intended to be used directly by a user, though
it certainly could be.  It could be used to generate static html,
or use a library like `elnode' to serve dynamic pages.  Or even to
extract a form from a site to produce an API.

TODO: Better documentation, more convenience.

NOTICE: Code base will be transitioning to using pcase instead of
destructuring bind wherever possible.  If this leads to hard to
debug code, please let me know, and I will do whatever I can to
resolve these issues.
