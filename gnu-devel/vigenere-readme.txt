A vigenere cipher is similar to a series of shift ciphers.  A key is repeated
through the plain text, then a shift cipher is used for each letter depending
on the letter in the key at that position.

Example:

The following uses the key EMACS (because what else would my example key be?).

Plain text: This is some plain text

First, we repeat the key through the plain text

This is some plain text
EMAC SE MACS EMACS EMAC

Then each letter in the plain text is shifted based on the key character at
that point:

This is some plain text
EMAC SE MACS EMACS EMAC
Xtiu aw eoow txakf xqxv

The specific shift amount for each character is the 0-based offset from A.
Therefore, A is 0, B is 1, etc.

The key in our case is case-insensitive.  EMACS is Emacs is emacs is EmACs.

One more note, is that this package only operates on letters, and the case of
the original text is preserved.

A vigenere cipher should not be considered cryptographically secure.  This
package is for recreational use only, not for securing sensitive information.