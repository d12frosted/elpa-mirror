This package is a port of OpenAIs tiktoken library, a package for
tokenizing utilizing a byte-pair encoder.

The first thing required for usrage of this library is an encoding.
An encoding object contains the necessary metadata to encode/decode
a piece of text.  The aspects of the encoding are pre-configured in
this package.

If you know the encoding you want, you can directly obtain it with
the following functions: `tiktoken-cl100k-base',
`tiktoken-p50k-edit', `tiktoken-p50k-base', and
`tiktoken-r50k-base'.  The initial call to these functions will
require parsing of the token-rank files.  These files are fetched
over the web and cached.  The caching mechanism saves the fetched
file to disk.  You can control where this file is saved with the
variable `tiktoken-cache-dir', or set it to nil to disable caching.
You may also set `tiktoken-offline-ranks' to read the rank files
directly from disk.  Note that these functions are memoized, allowing
subsequent calls to complete immediately.

If you don't know the encoding you want but know the model you are
using you can call the `tiktoken-encoding-for-model' function and
pass it the name of the model you are interested in using.

Once you have the encoding object, you will pass it to the
following functions to encode or decode:

- `tiktoken-encode-ordinary': directly encode the text not caring
  about special tokens.

- `tiktoken-encode': encode text, taking into account special
  tokens.

- `tiktoken-decode': decode a list of token IDs.

- `tiktoken-count-tokens': count the number of tokens in a given
   text.  Note that this function is optimized for performance and
   should be used if you only care about token length.
