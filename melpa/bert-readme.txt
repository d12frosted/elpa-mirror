Translation to and from BERT (Binary ERlang Term) format.

See the BERT specification at http://bert-rpc.org/.

The library provides two functions, `bert-pack' and `bert-unpack',
and supports the following Elisp types:
 - integers
 - floats
 - lists
 - symbols
 - vectors
 - strings

The Elisp NIL is encoded as an empty list rather than a BERT atom,
BERT nil, or BERT false.

Elisp vectors and strings are encoded as BERT tuples resp. BERT
binaries.

Complex types are not supported.  Encoding and decoding of complex
types can be implemented as a thin layer on top of this library.

Because Elisp integers are 30-bit, only integers of this size can
be correctly translated.  In particular, BERT bignums are not
supported.
