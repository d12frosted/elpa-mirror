Emacs wisi package 4.3.2

The wisi package provides utilities for using generalized
error-correcting LR parsers (in external processes) to do indentation,
fontification, and navigation; and integration with Emacs package.el.
See ada-mode for an example of its use.

It also provides wisitoken-parse_table-mode, for navigating the
diagnostic parse tables output by wisitoken-bnf-generate.

The generated code is in Ada; it can be built via Alire
(https://alire.ada.dev/). Normally this is done by a package that uses
wisi, such as ada-mode.
