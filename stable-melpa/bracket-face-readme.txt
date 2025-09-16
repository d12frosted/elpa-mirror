This package defines a face named `bracket-face'.

Enable `bracket-face-mode' to use that face for all brackets
in buffers whose major-mode is listed in `bracket-face-modes' or
which derives from a listed mode.

Alternatively, to enable use of that face for only a certain mode,
without affecting derived modes, use something like:

  (font-lock-add-keywords 'emacs-lisp-mode bracket-face-keywords)

You might also be interested in the `parenthesis-face' package.
