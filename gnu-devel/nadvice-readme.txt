This package tries to re-implement some of nadvice.el's functionality
on top of the old defadvice system, to help users of defadvice
move to the new advice system without dropping support for Emacs<24.4.

Limitations;
- only supports `advice-add', `advice-remove', and `advice-member-p'.
- only handles the :before, :after, :override, and :around kinds of advice;
- requires a named rather than anonymous function;
- and does not support any additional properties like `name' or `depth'.

It was tested on Emacs-22 and I can't see any obvious reason why it
wouldn't work on older Emacsen.