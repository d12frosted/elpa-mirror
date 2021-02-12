Provides an input method for flipping characters upside down by
selecting an appropriate character that looks upside down.
E.g. hello world -> p1ɹoʍ o11ǝɥ.

Copy the file in your load path and load it with
  (require 'fliptext).
Activate it with C-u C-\ fliptext RET.
Deactivate with C-\.

I didn't use `quail-define-package', because i couldn't figure out,
how to `backward-char' after conversion.

This file used uni-input.el as example, in particular
`fliptext-input-activate' is based on it.

This file is *NOT* part of GNU Emacs.
