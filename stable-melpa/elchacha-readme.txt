This library is a partial implementation of ChaCha20 stream cipher as per
RFC7539. The implementation hasn't been tested against any attacks and
shouldn't be used as the first choice when using a cryptographic
library.

The use-case I wrote this library for is a very limited one.  It's intended
for a personal use for platforms where using libraries such as OpenSSL is
inefficient, impractical or would simply require too much effort and baggage
involved for what it's simply supposed to do -- xor some things in a
particular way.
