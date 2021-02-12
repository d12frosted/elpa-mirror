AES (Rijndael) implementations for Emacs

This package provides AES algorithm to encrypt/decrypt Emacs
string. Supported algorithm desired to get interoperability with
openssl command. You can get decrypted text by that command if
you won't forget password.

## Install:

Put this file into load-path'ed directory, and
___!!!!!!!!!!!!!!! BYTE COMPILE IT !!!!!!!!!!!!!!!___
And put the following expression into your .emacs.

    (require 'kaesar)

## Usage:

* To encrypt a well encoded string (High level API)
`kaesar-encrypt-string' <-> `kaesar-decrypt-string'

* To encrypt a unibyte string with algorithm (Middle level API)
`kaesar-encrypt-bytes' <-> `kaesar-decrypt-bytes'

* To encrypt a unibyte with algorithm (Low level API)
`kaesar-encrypt' <-> `kaesar-decrypt'

## Sample:

* To encrypt my secret
  Please ensure that do not forget `clear-string' you want to hide.

    (defvar my-secret nil)

    (let ((raw-string "My Secret"))
      (setq my-secret (kaesar-encrypt-string raw-string))
      (clear-string raw-string))

* To decrypt `my-secret'

    (kaesar-decrypt-string my-secret)

## NOTE:

Why kaesar?
This package previously named `cipher/aes` but ELPA cannot handle
such package name.  So, I had to change the name but `aes` package
already exists. (That is faster than this package!)  I continue to
consider the new name which contains "aes" string. There is the
ancient cipher algorithm caesar
http://en.wikipedia.org/wiki/Caesar_cipher
 K`aes`ar is change the first character of Caesar. There is no
meaning more than containing `aes` word.

How to suppress password prompt?
There is no official way to suppress that prompt. If you want to
know more information, please read `kaesar-password` doc string.
