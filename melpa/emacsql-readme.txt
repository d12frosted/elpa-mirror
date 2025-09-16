EmacSQL is a high-level Emacs Lisp front-end for SQLite.

PostgreSQL and MySQL are also supported, but use of these connectors
is not recommended.

Any readable lisp value can be stored as a value in EmacSQL,
including numbers, strings, symbols, lists, vectors, and closures.
EmacSQL has no concept of TEXT values; it's all just lisp objects.
The lisp object `nil' corresponds 1:1 with NULL in the database.

See README.md for much more complete documentation.
