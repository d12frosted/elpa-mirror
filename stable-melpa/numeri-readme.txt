numeri

Numeri is an Emacs Lisp package to support the conversion of Hindu-Arabic
numbers to Roman and vice-versa. It is built off utility functions provided
by the Org (ox) and reStructuredText (rst) packages. Only integer numbers are
supported.

INSTALL

Install `numeri' from MELPA or MELPA stable. The commands in the package are
auto-loaded so no changes are required in your initialization file.

If installed from source, you will need to require the package `numeri' in
your Emacs initialization file.

  (require 'numeri)

USAGE

There are two commands provided:

- `numeri-arabic-to-roman'

  This command will accept either an Arabic integer number selected as a
  region or input via mini-buffer prompt and convert it to its Roman
  equivalent. The result is copied into the kill-ring.

- `numeri-roman-to-arabic'

  This command will accept either a Roman integer number selected as a region
  or input via mini-buffer prompt and convert it to its Arabic equivalent.
  The result is copied into the kill-ring.
