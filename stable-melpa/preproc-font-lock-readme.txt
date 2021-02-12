{{{ Documentation

*Preproc Font Lock* is an Emacs package that highlight C-style
preprocessor directives. The main feature is support for macros
that span multiple lines.

Preproc Font Lock is implemented as two minor modes:
`preproc-font-lock-mode' and `preproc-font-lock-global-mode'. The
former can be applied to individual buffers and the latter to all
buffers.

Installation:

Place this package in a directory in the load-path. To activate it,
use *customize* or place the following lines in a suitable init
file:

   (require 'preproc-font-lock)
   (preproc-font-lock-global-mode 1)

Customization:

You can customize this package using the following:

* `preproc-font-lock-preprocessor-background' -- The *face* used to
  highlight the preprocessor directive

* `preproc-font-lock-modes' -- A list of major modes. A buffer is
  highlighted if it's major mode is, or is derived from, a member
  of this list.

Example:

Below is a screenshot of a sample C file, demonstrating the effect
of this package:

![See doc/demo.png for screenshot of Preproc Font Lock](doc/demo.png)

}}}
