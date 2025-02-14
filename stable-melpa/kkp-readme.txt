kkp.el enables support for the Kitty Keyboard Protocol in Emacs.
This protocol is documented here:
https://sw.kovidgoyal.net/kitty/keyboard-protocol. It provides an
alternative, improved way to transmit keyboard input from a
terminal to Emacs running in that terminal.

For debugging key translation, see the file `kkp-debug.el`.

To load the debugging helpers, you can run:
   (require 'kkp-debug)

or M-x load-library RET kkp-debug RET
