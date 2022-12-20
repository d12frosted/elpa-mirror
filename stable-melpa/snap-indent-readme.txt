Snap-indent provides simple automatic indentation (and optional formatting)
when yanking/pasting text. It was inspired by `auto-indent-mode', and is
designed for improved simplicity, flexibility, and interoperability.

`snap-indent-mode' is an Emacs minor mode that enables the following
features:

- Indent inserted text according to major mode on yank/paste
- Indent buffer text according to major mode on save (optional)
- When indenting, additionally format text, e.g. tabify, untabify, remove
  trailing whitespace, etc (optional)
- Prevent minor mode activation in certain major modes (optional)

Snap-indent's additional formatting behavior is very flexible. Any function
that operates on a region may be used, and multiple functions may be
specified.
