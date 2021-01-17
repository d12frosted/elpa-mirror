With this package, you can efficiently navigate, edit and execute
code split into cells according to certain magic comments.  It also
allows to open ipynb notebook files directly in Emacs.  They will
be automatically converted to a script for editing, and converted
back to notebook format when saving.  An external tool, Jupytext by
default, is required for this.

Out of the box, there are no keybindings and, in fact, only a small
number of editing commands is provided.  Rather, the idea is that
you can create your own cell-aware commands from regular ones
through the `code-cells-command' function and the `code-cells-do' macro.  See
the README for configuration examples.  There is also a
`code-cells-mode' minor mode, which, among other things, provides
outline support.
