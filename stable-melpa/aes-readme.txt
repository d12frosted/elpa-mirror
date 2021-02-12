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
Version 25.3.1 is recommended
Versions 25.3 and earlier have not been tested for quite some time

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
- CBC mode is implemented straightforward, using a Zero [12] or
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
1.3.  Version 1.2 will be supported until at least December
2015. But it is advised to load and save all encrypted files using
this version

The latest version of this package is also available via MELPA [9]
and Marmalade [10].

There are two [13] other [14] Elisp implementations of AES.

Known Bugs / Limitations / TODO:
- This implementation is not resistant against DPA attacks [8].
- `aes-auto-decrypt' is not completely compliant to Emacs standards.
- Handle CBC and OCB in two different functions instead of the
  single function `aes-encrypt-buffer-or-string'.
- don't handle padding in `aes-cbc-encrypt'.
- refactor `aes-user-entropy'
- test random number generator

References:
 [1] http://csrc.nist.gov/archive/aes/rijndael/Rijndael-ammended.pdf
 [2] http://csrc.nist.gov/publications/fips/fips197/fips-197.pdf
 [3] http://www.openssl.org/
 [4] http://en.wikipedia.org/wiki/Block_cipher_modes_of_operation
 [5] http://tools.ietf.org/html/draft-krovetz-ocb-00
 [6] http://www.cs.ucdavis.edu/~rogaway/ocb/license.htm
 [7] http://tools.ietf.org/html/rfc5652#section-6.3
 [8] http://en.wikipedia.org/wiki/Differential_power_analysis
 [9] http://melpa.org/
[10] http://marmalade-repo.org/
[11] http://debbugs.gnu.org/cgi/bugreport.cgi?bug=15501
[12] http://en.wikipedia.org/wiki/Padding_(cryptography)#Zero_padding
[13] https://github.com/mhayashi1120/Emacs-kaesar/
[14] http://josefsson.org/aes/

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
