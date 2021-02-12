`plisp-mode' provides a major mode for PicoLisp programming.

The `plisp-mode' in this package has been built from scratch, and
is not based on, nor connected with, the PicoLisp support for Emacs
provided in [the PicoLisp
distribution](http://software-lab.de/down.html), or the more
recently [updated version of that
support](https://github.com/tj64/picolisp-mode). At this stage, the
main advantages provided by this package are:

* an actively maintained and supported system;

* access to the PicoLisp reference documentation, including via
  Eldoc;

* basic Imenu support;

* ease of customisability; and

* a cleaner codebase.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
 - [Syntax highlighting](#highlighting)
 - [REPL](#repl)
 - [Inferior PicoLisp](#inferior-picolisp)
  - [Org Babel](#org-babel)
 - [Documentation](#documentation)
 - [Commenting](#commenting)
 - [Indentation](#indentation)
 - [Miscellaneous](#miscellanous)
- [TODO](#todo)
- [Issues](#issues)
- [License](#license)

## Features

* Syntax highlighting of PicoLisp code. (But please read the below
  [note on syntax highlighting](#note-highlighting).)

* Comint-based `pil' REPL buffers.

* Quick access to documentation for symbol at point.

## Installation

Install [plisp-mode from
MELPA](http://melpa.org/#/plisp-mode), or put the
`plisp-mode' folder in your load-path and do a `(require
'plisp-mode)'.

## Usage

<a name='highlighting'></a>

### Syntax highlighting

Enable syntax highlighting for a PicoLisp source buffer with `M-x
plisp-mode'.

### REPL

Start a `pil' REPL session with `M-x plisp-repl' or, from a
`plisp-mode' buffer, with `C-c C-i' (`plisp-repl').

<a name='inferior-picolisp'></a>

### Inferior PicoLisp

This package provides the `inferior-plisp' feature, a fork of the
[`inferior-picolisp' library written by Guillermo Palavecino and
Thorsten Jolitz](https://github.com/tj64/picolisp-mode/), modified
to be compatible with `plisp-mode'.

By default, `inferior-plisp' is loaded by `plisp-mode'; to disable
this, set the variable `plisp-use-inferior-plisp' to `nil'. It can
still be manually loaded with `(require 'inferior-plisp)'.

With `inferior-plisp' loaded, the following bindings are available
in `plisp-mode' and `plisp-repl-mode':

* `M-C-x' / `C-c C-e' : Send the current definition to the inferior PicoLisp
  process (`inferior-plisp-send-definition').

* `C-x C-e' : Send the last sexp before point to the inferior
  PicoLisp process (`inferior-plisp-send-last-sexp').

* `C-c M-e' : Send the current definition to the inferior PicoLisp
  process and switch to its buffer
  (`inferior-plisp-send-definition-and-go').

* `C-c C-r' : Send the region to the inferior PicoLisp process
  (`inferior-plisp-send-region').

* `C-c M-r' : Send the region to the inferior PicoLisp process and
  switch to its buffer (`inferior-plisp-send-region-and-go').

* `C-c C-l' : Load a PicoLisp file into the inferior PicoLisp
  process (`inferior-plisp-load-file')."

* `C-c C-x' : Switch to the inferior PicoLisp buffer
  (`inferior-plisp-switch-to-picolisp').

Multiple inferior PicoLisp processes can be created and used; the
documentation for the variable `inferior-plisp-picolisp-buffer'
provides more details.

By default, `inferior-plisp' provides the feature
`inferior-picolisp' required by `ob-picolisp'. To use another
package to provide `inferior-picolisp', set the
`inferior-plisp-provide-inferior-picolisp' variable to `nil'.

<a name='org-babel'></a>

#### Org Babel

By default, `plisp-mode' registers itself as providing the
`picolisp-mode' needed to edit Org Babel PicoLisp source blocks
with `org-edit-special'. If you wish to disable this, set the
variable `plisp-provide-picolisp-mode' to `nil'.

`inferior-plisp' can support Org Babel sessions: add
`(inferior-plisp-support-ob-picolisp)' to your init file, and make
sure the `org-babel-picolisp-cmd' variable defined by `ob-picolisp'
is correctly specified for your system.

### Documentation

Access documentation for the function at point with `C-c C-d'
(`plisp-describe-symbol'). By default, documentation will be
displayed via the `lynx' HTML browser. However, one can set the
value of `plisp-documentation-method' to either a string
containing the absolute path to an alternative browser, or - for
users of Emacs 24.4 and above - to the symbol
`plisp--shr-documentation'; this function uses the `shr' library
to display the documentation in an Emacs buffer. The absolute path
to the documentation is specified via
`plisp-documentation-directory', and defaults to
`/usr/share/doc/picolisp/'.

Eldoc support is available.

If for some reason the PicoLisp documentation is not installed on
the system, and cannot be installed, setting
`plisp-documentation-unavailable' to `t' will prevent
`plisp-mode' from trying to provide documentation.

### Commenting

Comment a region in a `plisp-mode' buffer with `C-c C-;'
(`plisp-comment-region'); uncomment a region in a
`plisp-mode' buffer with `C-c C-:'
(`plisp-uncomment-region'). By default one '#' character is
added/removed; to specify more, supply a numeric prefix argument to
either command.

### Indentation

Indent a region in a `plisp-mode' buffer with `C-c M-q'
(`plisp-indent-region'). Indentation is done via the `pilIndent'
script provided with the current PicoLisp distribution; the path to
the script is specified via the `plisp-pilindent-executable'
variable.

### Miscellaneous

SLIME users should read the below [note on SLIME](#note-slime).

The various customisation options, including the faces used for
syntax highlighting, are available via the `plisp'
customize-group.

<a name="note-highlighting"></a>

### A note on syntax highlighting

PicoLisp's creator is opposed to syntax highlighting of symbols in
PicoLisp, for [good
reasons](http://www.mail-archive.com/picolisp@software-lab.de/msg05019.html).
However, some - such as the author of this package! - feel that,
even taking such issues into consideration, the benefits can
outweigh the costs. (For example, when learning PicoLisp, it can be
useful to get immediate visual feedback about unintentionally
redefining a PicoLisp 'builtin'.) To accommodate both views, syntax
highlighting can be enabled or disabled via the
`plisp-syntax-highlighting-p' variable; by default, it is set to
`t' (enabled).

<a name="note-slime"></a>

### A note on [SLIME](https://github.com/slime/slime)

The design of SLIME is such that it can override `plisp-mode'
functionality. (The documentation for
`plisp--disable-slime-modes' provides details.) The
user-customisable variable `plisp-disable-slime-p' specifies
whether to override these overrides, and defaults to `t'.

## TODO

* Fix misalignment of single-'#' comments upon newline.

<a name="issues"></a>

## Issues / bugs

If you discover an issue or bug in `plisp-mode' not already
noted:

* as a TODO item, or

* in [the project's "Issues" section on
  GitHub](https://github.com/flexibeast/plisp-mode/issues),

please create a new issue with as much detail as possible,
including:

* which version of Emacs you're running on which operating system,
  and

* how you installed `plisp-mode'.

## License

[GNU General Public License version
3](http://www.gnu.org/licenses/gpl.html), or (at your option) any
later version.
