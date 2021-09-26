With this package, you can efficiently navigate, edit and execute
code split into cells according to certain magic comments.  It also
allows to open ipynb notebook files directly in Emacs.  They will
be automatically converted to a script for editing, and converted
back to notebook format when saving.  An external tool, Jupytext by
default, is required for this.

A minor mode, `code-cells-mode`, provides the following features:

- Fontification of cell boundaries.

- Keybindings for the cell navigation and evaluation commands,
  under the `C-c %' prefix.

- Outline mode integration: cell headers have outline level
  determined by the number of percent signs or asterisks; within a
  cell, outline headings are as determined by the major mode, but
  they are demoted by an amount corresponding to the level of the
  containing cell.  This provides code folding and hierarchical
  navigation, among other things, when `outline-minor-mode` is
  active.

This minor mode is automatically activated when opening an ipynb
file, but you can also activate it in any other buffer, either
manually or through some hook.
