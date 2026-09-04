This file provides a generic infrastructure for cross referencing
commands, such as "find definition".

The unique functionality is configured by defining an xref backend.
That consists of a constructor function, and implementations for the
generic functions (using `cl-defmethod').

The constructor should return a value that `cl-defmethod' can
dispatch on.  Most often it is a plain symbol, such as `elisp'.
A major or minor mode would use `add-hook' to set itself up and add
the backend constructor to `xref-backend-functions'.

Some important backend methods to define are:

`xref-backend-identifier-at-point',
`xref-backend-identifier-completion-table',
`xref-backend-definitions', `xref-backend-references',
`xref-backend-apropos'.

And more optional ones:

`xref-backend-identifier-completion-ignore-case',
`xref-backend-identifier-completion-predicate',
`xref-backend-xref-kinds' and `xref-backend-xrefs-by-kind'.

The methods which return a list of results (such as "definitions")
operate with "xref" and "location" values.  Locations are values that
also can be dispatched on by `cl-defmethod', usually cl-structs.

One would usually call `xref-make' and `xref-make-file-location',
`xref-make-buffer-location' or `xref-make-bogus-location' to create
them.  The latter functions correspond to built-in location types.

More generally, a location must also be values that `cl-defmethod'
can dispatch on, usually cl-strincs.  Each of them implements
`xref-location-group' and `xref-location-marker'.
`xref-location-line' is optional.

There is a special category of xrefs we call "match xrefs", which
correspond to search results that have spans.  For these values,
`xref-match-length' must be defined, and `xref-location-marker' must
return the beginning of the match.

Each identifier must be represented as a string.  Definitions can use
string properties to store additional information about the
identifier, but strings in `xref-backend-identifier-completion-table'
should still be distinct, because the user can't see the text
properties when making the choice.

Older versions of Xref used EIEIO for implementation of the
built-in types, and included a class called `xref-location' which
was supposed to be inherited from.  Neither is true anymore.

See the implementations in `elisp-mode', `eglot' and `etags' for more
complete examples.