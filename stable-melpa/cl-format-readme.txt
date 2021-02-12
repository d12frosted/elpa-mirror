This package implements a CL format routine.

Features:
* Supports most CL format directives.
* CL `format' and `formatter' functions implemented.
* Format strings are compiled to elisp.
* Output stream may be anything accepted by `standard-output', nil
  or t.
* Custom directives may be easily implemented (see
  `define-cl-format-directive')
* Partially based on GNU CLISP's format.
* Fontifys format strings.
* Extends CL format in some ways.

Deviations from CL:
* Directives are case-sensitive

  All CL letter directives use a lower case character (the `v' as
  well).  This leaves upper-case character for user defined
  directives.

* Different case-change directive

  I wanted to have a general way of defining directives like ~[~],
  without running out of memorizable end character.  For this the
  ~(~) directive was moved.  The extended syntax allows for
  any char to open a enclosing region:
      ~CHAR(....~)
  The CL case change operation is now
      ~|(...~)
  The original CL directive ~| (inserts ) is gone.
* Some minor additions (e.g. ~% may indent the line)

Installation:

Put all files in `load-path' and (require 'cl-format) .

Put the next line in your init file, if you want colored format strings.
(add-hook 'emacs-lisp-mode-hook 'cl-format-font-lock-mode)

Usage:

See the documentation of `cl-format'.  If you want to write your
own directives, take at look at some simple CL directives (e.g. ~%)
in cl-format-builtins.el and then proceed to the
`define-cl-format-directive' macro.
