`sqlind-minor-mode' is a minor mode that enables syntax-based indentation
for `sql-mode' buffers: the TAB key indents the current line based on the
SQL code on previous lines.  To setup syntax-based indentation for every
SQL buffer, add `sqlind-minor-mode' to `sql-mode-hook'.  Indentation rules
are flexible and can be customized to match your personal coding style.
For more information, see the "sql-indent.org" file.

The package also defines align rules so that the `align' function works for
SQL statements, see `sqlind-align-rules'.