Unformatted vcards are just plain ugly.  But if you live in the MIME
world, they are a better way of exchanging contact information than
freeform signatures since the former can be automatically parsed and
stored in a searchable index.

This library of routines provides the back end necessary for parsing
vcards so that they can eventually go into an address book like BBDB
(although this library does not implement that itself).  Also included
is a sample pretty-printer which MUAs can use which do not provide their
own vcard formatters.

This library does not interface directly with any mail user agents.  For
an example of bindings for the VM MUA, see vm-vcard.el available from

   http://www.splode.com/~friedman/software/emacs-lisp/index.html#mail

Updates to vcard.el should be available there too.

The main entry point to this package is `vcard-pretty-print' although
any documented variable or function is considered part of the API for
operating on vcard data.

The vcard 2.1 format is defined by the versit consortium.
See http://www.imc.org/pdi/vcard-21.ps

RFC 2426 defines the vcard 3.0 format.
See ftp://ftp.rfc-editor.org/in-notes/rfc2426.txt

A parsed vcard is a list of attributes of the form

    (proplist value1 value2 ...)

Where proplist is a list of property names and parameters, e.g.

    (property1 (property2 . parameter2) ...)

Each property has an associated implicit or explicit parameter value
(not to be confused with attribute values; in general this API uses
`parameter' to refer to property values and `value' to refer to attribute
values to avoid confusion).  If a property has no explicit parameter value,
the parameter value is considered to be `t'.  Any property which does not
exist for an attribute is considered to have a nil parameter.

TODO:
  * Consolidate the functionality duplicated between `vcard.el' and
    `vcard-parse.el'.
  * Finish supporting the 3.0 extensions.
    Currently, only the 2.1 standard is supported by `vcard.el'
    But newer 4.0 is supported by `vcard-parse.el'.
  * Handle nested vcards and grouped attributes?
    (I've never actually seen one of these in use.)
  * Handle multibyte charsets.
  * Inverse of vcard-parse-string: write .VCF files from alist
  * Implement a vcard address book?  Or is using BBDB preferable?
  * Improve the sample formatter.

News:

Since 0.2.1:
- Incorporated the code from Noah Friedman's vcard.el