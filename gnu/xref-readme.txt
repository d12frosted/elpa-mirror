This file provides a somewhat generic infrastructure for cross
referencing commands, in particular "find-definition".

Some part of the functionality must be implemented in a language
dependent way and that's done by defining an xref backend.

That consists of a constructor function, which should return a
backend value, and a set of implementations for the generic
functions:

`xref-backend-identifier-at-point',
`xref-backend-identifier-completion-table',
`xref-backend-definitions', `xref-backend-references',
`xref-backend-apropos', which see.

A major mode would normally use `add-hook' to add the backend
constructor to `xref-backend-functions'.

The last three methods operate with "xref" and "location" values.

One would usually call `make-xref' and `xref-make-file-location',
`xref-make-buffer-location' or `xref-make-bogus-location' to create
them.  More generally, a location must be an instance of an EIEIO
class inheriting from `xref-location' and implementing
`xref-location-group' and `xref-location-marker'.

There's a special kind of xrefs we call "match xrefs", which
correspond to search results.  For these values,
`xref-match-length' must be defined, and `xref-location-marker'
must return the beginning of the match.

Each identifier must be represented as a string.  Implementers can
use string properties to store additional information about the
identifier, but they should keep in mind that values returned from
`xref-backend-identifier-completion-table' should still be
distinct, because the user can't see the properties when making the
choice.

See the etags and elisp-mode implementations for full examples.