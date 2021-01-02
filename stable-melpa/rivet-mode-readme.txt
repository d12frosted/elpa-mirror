
[![MELPA: rivet-mode](https://melpa.org/packages/rivet-mode-badge.svg)](https://melpa.org/#/rivet-mode) [![ISC License](https://img.shields.io/badge/license-ISC-green.svg)](./LICENSE) [![](https://img.shields.io/github/languages/code-size/thornjad/rivet-mode.svg)](https://gitlab.com/thornjad/rivet-mode) [![](https://img.shields.io/github/v/tag/thornjad/rivet-mode.svg?label=version&color=yellowgreen)](https://gitlab.com/thornjad/rivet-mode/-/tags)

Rivet mode is a minor mode for editing Apache Rivet files. It automatically
detects whether TCL or HTML is currently being edited and uses the major
modes tcl-mode and web-mode, respectively.

By default, `rivet-mode' requires `tcl' (built-in) and `web-mode'. To use
another mode, customize `rivet-mode-host-mode' and `rivet-mode-inner-mode' to
suit.

Installation:

Install the `rivet-mode' package from MELPA.

Usage:

The mode will be activated upon opening a Rivet file. There are a handful of
convenient function available inside this file. It is recommended to bind
these to keys of your choosing.

Provided functions:

- `rivet-insert-tcl': Insert TCL tags ("<?" and "?>") at point, and move point
inside of the tags. This will also switch to TCL mode.

- `rivet-insert-begin-tcl': Insert an opening TCL tag at point and move inside
it.

- `rivet-insert-end-tcl': Insert a closing TCL tag at point and move outside
it. This will also switch to web mode.

- `rivet-insert-echo': Insert TCL echo tags ("<?=" and "?>") at point and move
inside them. This will also switch to TCL mode.

- `rivet-insert-begin-echo': Insert an opening TCL echo tag at point and move
inside it.

Customization:

The variable `rivet-mode-host-mode' determines the "host" major mode, which
is `web-mode' by default.

The variable `rivet-mode-inner-mode' determines the "inner" major mode, which
is the built-in `tcl-mode' by default.

The variable `rivet-mode-delimiters' defines the left and right delimiters
which demark the bounds of the "inner" major mode (TCL). These are "<?" and
"?>" by default. Note that the "<?=" delimiter, which marks the start of an
expression, still begins with "<?" and so will be caught.
