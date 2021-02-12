
For usage and explanations see https://www.emacswiki.org/emacs/SQLite-el.

1 sqlite.el
═══════════

  SQLite Interface through Elisp programming.


2 From EmacsWiki
════════════════

  This code was retrieved from the EmacsWiki at december 26, 2013.

  Contributors:

  ⁃ @mariotomo (Mario Frasca)
  ⁃ @cnngimenez
  ⁃ @kidd (Raimon Grau)


3 Features
══════════

  This interface has the following features:

  • Can connect to several database files.
  • No output buffer shown. The output buffer is hidden when using the
    interface.
  • SQLite errors match.
  • Files does not need to be in absolute path. It is expanded using
    `expand-file-name' command.
  • Timeout sub-process output retrieving for each result row. See
    `sqlite-response-timeout' variable.


4 Usage
═══════

  See usage and more information at the [SQLite EmacsWiki page].

  Here is an example to query the database:

  ┌────
  │ (require 'sqlite)
  │
  │ typical usage involves three functions
  │ (let ((db (sqlite-init "~/mydb.sqlite")))  open connection
  │   (unwind-protect  perform body, return value, then clean up
  │       (let ((res (sqlite-query db "SELECT * FROM my_table")))
  │ 	Make more queries...  more calculations ...
  │ 	...
  │ 	res)  the return value
  │     (sqlite-bye db)))  close connection
  └────


[SQLite EmacsWiki page] <https://www.emacswiki.org/emacs/SQLite-el>


5 Licence
═════════

  This work is under the GNU GPLv3 licence.


6 Happy Coding!
═══════════════
