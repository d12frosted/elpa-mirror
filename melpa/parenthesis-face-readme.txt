This package defines a face named `parenthesis-face'.

Enable `parenthesis-face-mode' to use that face for all parentheses
in buffers whose major-mode is listed in `parenthesis-face-modes' or
which derives from a listed mode.

Alternatively, to enable use of that face for only a certain mode,
without affecting derived modes, use something like:

  (font-lock-add-keywords 'emacs-lisp-mode parenthesis-face-keywords)

You might also be interested in the `bracket-face' package.
