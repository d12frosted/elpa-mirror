This package may be useful if you’d just like to encrypt parts of
files or buffers, and to have encrypted output in the same line as
other unencrypted text.

This package relies on the openssl command-line utility. If openssl
isn't in your PATH, customize the `inline-crypt-openssl-command'
variable to point to it.

The four interactive commands that will interest you are
`inline-crypt-encrypt-region', `inline-crypt-decrypt-region',
`inline-crypt-encrypt-string', and `inline-crypt-decrypt-string'.
