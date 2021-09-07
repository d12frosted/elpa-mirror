Puni is a package for structured editing.  Its main features are:

- A set of customizable soft deletion commands, enabled by `puni-mode'.
  Soft deletion means deleting while keeping expressions balanced.
- A simple API `puni-soft-delete-by-move', for defining your own soft
  deletion commands.
- Sexp navigating and manipulating commands.
- Completely based on Emacs built-in mechanisms, doesn't contain any
  language-specific logic, yet work on many major modes.

It's recommended to use Puni with `electric-pair-mode'.  Read README.md to
know more about Puni.  If you haven't received such a file, please visit
https://github.com/AmaiKinono/puni.
