This package provides a major mode for editing BASIC code.  Features
include syntax highlighting and indentation, as well as support for
auto-numbering and renumering of code lines.

The base mode provides basic functionality and is normally only used
to derive sub modes for different BASIC dialects, see for example
`basic-generic-mode'.  For a list of available sub modes, please see
https://github.com/dykstrom/basic-mode, or the end of the source code
file.

By default, basic-mode will open BASIC files in the generic sub mode.
To change this, you can use a file variable, or associate BASIC files
with another sub mode in `auto-mode-alist'.

You can format the region, or the entire buffer, by typing C-c C-f.

When line numbers are turned on, hitting the return key will insert
a new line starting with a fresh line number.  Typing C-c C-r will
renumber all lines in the region, or the entire buffer, including
any jumps in the code.

Type M-. to lookup the definition of the identifier at point, and type M-,
to go back again. See also function `xref-find-definitions'.

Installation:

The recommended way to install basic-mode is from MELPA, please see
https://melpa.org.

To install manually, place basic-mode.el in your load-path, and add
the following lines of code to your init file:

(autoload 'basic-generic-mode "basic-mode" "Major mode for editing BASIC code." t)
(add-to-list 'auto-mode-alist '("\\.bas\\'" . basic-generic-mode))

Configuration:

You can customize the indentation of code blocks, see variable
`basic-indent-offset'.  The default value is 4.

Formatting is also affected by the customizable variables
`basic-delete-trailing-whitespace' and `delete-trailing-lines'
(from simple.el).

You can also customize the number of columns to allocate for
line numbers using the variable `basic-line-number-cols'. The
default value of 0 (no space reserved), is appropriate for
programs with no line numbers and for left aligned numbering.
Use a positive integer, such as 6, if you prefer right alignment.

The other line number features can be configured by customizing
the variables `basic-auto-number', `basic-renumber-increment' and
`basic-renumber-unnumbered-lines'.

Whether syntax highlighting requires separators between keywords can be
customized with variable `basic-syntax-highlighting-require-separator'.
