This package provides a strict and robust [bencode][bencode]
encoder and decoder. Encoding is precise, taking into account
character encoding issues. As such, the encoder always returns
unibyte data intended to be written out as raw binary data without
additional character encoding. When encoding strings and keys,
UTF-8 is used by default. The decoder strictly valides its input,
rejecting invalid inputs.

The API entrypoints are:
* `bencode-encode'
* `bencode-encode-to-buffer'
* `bencode-decode'
* `bencode-decode-from-buffer'
