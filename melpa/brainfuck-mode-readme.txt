This library helps you to write brainfuck in Emacs.
This is also an example to define help document functions by using langdoc.

Requirements:
  * Emacs 24 or later
  * langdoc.el

To use this package, add the following line to your .emacs file:
    (require 'brainfuck-mode)
brainfuck-mode highlights some keywords for usability.
By using M-x eldoc-mode, you can see the help string in minibuffer.
Also, by using M-x bf-help-describe-symbol (or C-c f), you can see
more documents for each command.
