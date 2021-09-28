An alternative EmacsSQL back-end for SQLite, which uses an Emacs
module that exposes parts of the SQLite C API to elisp, instead of
using subprocess as `emacsql-sqlite' does.  The module is provided
by the `sqlite3' package.

The goal is to provide a more performant and resilent drop-in
replacement for `emacsql-sqlite'.  Taking full advantage of the
granular module functions currently isn't a goal.
