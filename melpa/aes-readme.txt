This library provides support for saving files in an encrypted form
by using Cipher-block chaining [4] and Offset Codebook Mode [5].
Both use Rijndael [1] as encryption algorithm, which is implemented
natively in Emacs.  Rijndael is a superset of the AES algorithm
[2].  Additionally this library provides a password generator based
on AES and random user input.  For patent issues about OCB see [6],
which allows this distribution.

Config file
Insert "(require 'aes)" into your local .emacs file to load this
library.
Insert "(aes-enable-auto-decryption)" into yout local .emacs file
for convenient automatic recognization of encrypted files during
loading.

Whenever possible, this library should be used byte-compiled, as
this provides a really great performance boost!

Main entry points:

`aes-encrypt-current-buffer' / `aes-decrypt-current-buffer' Ask for
password and encrypt / decrypt current buffer.
`aes-insert-password' Generate a random password from user input.

For customizing this library, there is the customization group aes
in the applications group.

Emacs compatibility:
Version 27 is recommended
Version 26 has not been tested
Version 25 and earlier are incompatible

This implementation allows additionally to the AES specification
blocklengths of 24 and 32 bytes.

Nb denotes the number of 32-bit words in the state.
Nk denotes the number of 32-bit words comprising the cipher key.
Nr denotes the number of rounds.
We allow Nb and Nk to be 4, 6, or 8. and Nr = max(Nb, Nk) + 6

Since Emacs implements integers as 29 bit numbers, it is not
possible to use the optimization, which requires 32 bit numbers.
For details see [3].  This leads to an 8-bit design for this
implementation.  So the following fitting implementation is used
here.
- Multiplication and inverting in GF(2^8) are implemented as table
  lookups.
- The state is implemented as a unibyte string of length 4 * Nb.
- Plaintext and ciphertext are implemented as unibyte strings.
- The expanded key is implemented as a list of length 4 * Nb * (1 +
  Nr) with entries '((A . B) . (C . D)), where A, B, C and D are
  bytes.  It is precalculated before the en-/decryption algorithms.
- The S-boxes are implemented by lookup tables.
- The three operations ByteSub, ShiftRow and MixColumn together
  with round-key-addition are implemented in the functions
  `aes-SubShiftMixKeys' and `aes-InvSubShiftMixKeys' for encryption
  and decryption respectively.
- CBC mode is implemented straightforward, using a Zero [10] or
  PKCS#7 [7] padding.  The IV is appended to and saved with the
  ciphertext.
- OCB mode made the implementation of a pmac, based on AES,
  necessary, but the further details were straightforward.  The IV
  is appended to the ciphertext.  During decryption the created
  hash-value is checked.
- the function `aes-key-from-passwd' generates an AES key from an
  user input string (password).
- Further `aes-insert-password' generates random passwords, based
  on random user input like mousemovement, time and keyinput.

The version of the internal storage format of encrypted data is
Version 1.3.  If you need to decrypt data stored in Version 1.2,
please use Verion 0.9 of this library or an earlier one.

The latest version of this package is also available via MELPA [9].

There are two [11] other [12] Elisp implementations of AES.

Known Bugs / Limitations / TODO:
- This implementation is not resistant against DPA attacks [8].
- `aes-auto-decrypt' is not completely compliant to Emacs standards.
- Handle CBC and OCB in two different functions instead of the
  single function `aes-encrypt-buffer-or-string'.
- don't handle padding in `aes-cbc-encrypt'.
- refactor `aes-user-entropy'
- test random number generator
- make use of 32 bit integer support

References:
 [1] https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/aes-development/rijndael-ammended.pdf
 [2] https://csrc.nist.gov/csrc/media/publications/fips/197/final/documents/fips-197.pdf
 [3] https://www.openssl.org/
 [4] https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation
 [5] https://datatracker.ietf.org/doc/html/draft-krovetz-ocb-00
 [6] https://www.cs.ucdavis.edu/~rogaway/ocb/license.htm
 [7] https://datatracker.ietf.org/doc/html/rfc5652#section-6.3
 [8] https://en.wikipedia.org/wiki/Power_analysis#Differential_power_analysis
 [9] https://melpa.org/
[10] https://en.wikipedia.org/wiki/Padding_(cryptography)#Zero_padding
[11] https://github.com/mhayashi1120/Emacs-kaesar/
[12] https://josefsson.org/aes/

This program is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see
<http://www.gnu.org/licenses/>.
