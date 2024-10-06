This package provides a major mode for editing GenExpr files used in
Max/MSP's gen~ object.  It includes syntax highlighting and indentation
support for GenExpr code.

To use this mode, simply open a .genexpr file or add the following to
your Emacs configuration:

(require 'genexpr-mode)
(add-to-list 'auto-mode-alist '("\\.genexpr\\'" . genexpr-mode))
