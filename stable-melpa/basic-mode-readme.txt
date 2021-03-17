This package provides a major mode for editing BASIC code.  Features
include syntax highlighting and indentation, as well as support for
auto-numbering and renumering of code lines.

You can format the region, or the entire buffer, by typing C-c C-f.

When line numbers are turned or, hitting the return key will insert
a new line starting with a fresh line number.  Typing C-c C-r will
renumber all lines in the region, or the entire buffer, including
any jumps in the code.

Type M-. to lookup the line number, label, or variable at point,
and type M-, to go back again.  See also function
`xref-find-definitions'.

Installation:

The recommended way to install basic-mode is from MELPA, please see
https://melpa.org.

To install manually, place basic-mode.el in your load-path, and add
the following lines of code to your init file:

(autoload 'basic-mode "basic-mode" "Major mode for editing BASIC code." t)
(add-to-list 'auto-mode-alist '("\\.bas\\'" . basic-mode))

Configuration:

You can customize the indentation of code blocks, see variable
`basic-indent-offset'.  The default value is 4.

Formatting is also affected by the customizable variables
`basic-delete-trailing-whitespace' and `delete-trailing-lines'
(from simple.el).

You can also customize the number of columns to use for line
numbers, see variable `basic-line-number-cols'.  The default value
is 0, which means not using line numbers at all.

The other line number features can be configured by customizing
the variables `basic-auto-number', `basic-renumber-increment' and
`basic-renumber-unnumbered-lines'.
