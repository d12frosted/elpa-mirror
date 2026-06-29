This package provides SMIE support for SQL-mode.

It is currently quite inferior to `sql-indent' at indenting SQL code because
it only handles a tiny subset of the SQL language, so don't bother trying it
out for that purpose unless you're interested in improving it.

To make use of it, you can do something like:

    (add-hook 'sql-mode-hook #'sql-smie-enable)

It can be used together with `sql-indent', where `sql-indent' takes care
of indenting and `sql-smie' is used for navigation, auto-fill, blink-paren,
etc...