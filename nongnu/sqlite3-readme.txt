1 SQLite3 API for Emacs 25+
═══════════════════════════

1.1 Introduction
────────────────

  `sqlite3' is a dynamic module for GNU Emacs 25+ that provides direct
  access to the core SQLite3 C API from Emacs Lisp.
  ┌────
  │ (require 'sqlite3)
  │ 
  │ (setq dbh (sqlite3-open "person.sqlite3" sqlite-open-readwrite sqlite-open-create))
  │ (sqlite3-exec dbh "create table temp (name text, age integer)")
  │ (setq stmt (sqlite3-prepare dbh "insert into temp values (?,?)"))
  │ (cl-loop for i from 1 to 10 do
  │ 	 (sqlite3-bind-multi stmt (format "name%d" i) i)
  │ 	  ;; execute the SQL
  │ 	 (sqlite3-step stmt)
  │ 	 ;; call reset if you want to bind the SQL to a new set of variables
  │ 	 (sqlite3-reset stmt))
  │ (sqlite3-finalize stmt)
  │ 
  │ (setq stmt (sqlite3-prepare dbh "select * from temp"))
  │ (while (= sqlite-row (sqlite3-step stmt))
  │   (cl-destructuring-bind (name age) (sqlite3-fetch stmt)
  │     (message "name: %s, age: %d" name age)))
  │ (sqlite3-finalize stmt)
  │ (sqlite3-close dbh)
  └────

  While this module provides only 14 functions (vs [200+ in the C API]),
  it should satisfy most users' needs.

  The current version is v0.17.

  This is an alpha release so it might crash your Emacs. Save your work
  before you try it out!


[200+ in the C API] <https://sqlite.org/c3ref/funclist.html>


1.2 Table of Contents
─────────────────────

  • 

    • 
    • 
    • 

      • 
      • 
      • 
      • 
      • 
    • 

      • 
      • 
      • 
      • 
      • 
      • 
      • 
      • 
      • 
      • 
      • 
      • 
      • 
      • 
      • 
    • 
    • 
    • 
    • 
    • 
    • 
    • 
    • 


1.3 Requirements
────────────────

  • Emacs 25.1 or above, compiled with module support (`./configure
    --with-modules'). Emacs 27.1 supports dynamic modules by default
    unless you explicitly disable it.
  • SQLite3 v3.16.0 or above. Older versions might work but I have not
    personally tested those.
  • A C99 compiler

  It's been tested on macOS (Catalina) and CentOS 7.


1.4 Installation & Removal
──────────────────────────

1.4.1 Melpa
╌╌╌╌╌╌╌╌╌╌╌

  The package is available on [Melpa] (thanks to @tarsius).

  The first time you `(require 'sqlite3)', you will be asked to confirm
  the compilation of the dynamic module:

  ┌────
  │ sqlite3-api module must be built.  Do so now?
  └────

  After the module is successfully compiled, you should `(unload-feature
  'sqlite3)' and then `(require sqlite3)' to reload properly.


[Melpa] <https://melpa.org/#/sqlite3>


1.4.2 Elpa
╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ $ git co https://github.com/pekingduck/emacs-sqlite3-api
  │ $ cd emacs-sqlite3-api
  │ $ make module
  └────

  A tar archive called `sqlite3-X.Y.tar' will be created. Do a `M-x
  package-install-file' in Emacs to install that tar archive and you're
  all set.

  For Mac users:
  ┌────
  │ $ make HOMEBREW=1
  └────
  to build the module against sqlite3 installed by Homebrew.

  If you have sqlite3 installed in a nonstandard location:
  ┌────
  │ $ make INC=/path/to/sqlite3/include LIB="-L/path/to/sqlite3/lib -lsqlite3"
  └────


1.4.3 Manual Installation
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ $ git co https://github.com/pekingduck/emacs-sqlite3-api
  │ $ cd emacs-sqlite3-api
  │ $ make
  │ $ cp sqlite3.el sqlite3-api.so /your/elisp/load-path/
  └────


1.4.4 Removal
╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you installed manually, just remove `sqlite3.el' and
  `sqlite3-api.so' from your load path. Otherwise, do `M-x
  package-delete' to remove the sqlite3 package.


1.4.5 Note on Package Update
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Emacs 25 and 26: If you are updating from an older version, you'll
  need to restart Emacs for the new module to take effect. That's
  because `unload-feature' doesn't work for dynamic modules.

  Emacs 27.1: I can't find it in [`etc/NEWS'], but it seems Emacs 27.1
  does support unloading of dynamic modules. To unload `sqlite3'
  properly:

  ┌────
  │ (unload-feature 'sqlite3)
  │ (unload-feature 'sqlite3-api)
  └────


[`etc/NEWS']
<https://github.com/emacs-mirror/emacs/blob/emacs-27.1/etc/NEWS>


1.5 API
───────

  To load the package, put the following in your `.emacs':

  ┌────
  │ (require 'sqlite3)
  └────

  An application will typically use sqlite3_open() to create a single
  database connection during initialization.

  To run an SQL statement, the application follows these steps:

  1. Create a prepared statement using sqlite3_prepare().
  2. Evaluate the prepared statement by calling sqlite3_step() one or
     more times.
  3. For queries, extract results by calling sqlite3_column() in between
     two calls to sqlite3_step().
  4. Destroy the prepared statement using sqlite3_finalize().
  5. Close the database using sqlite3_close().

  [SQlite3 constants], defined in sqlite3.h, are things such as numeric
  result codes from various interfaces (ex: `SQLITE_OK') or flags passed
  into functions to control behavior (ex: `SQLITE_OPEN_READONLY').

  In elisp they are in lowercase and words are separated by "-" instead
  of "_". For example, `SQLITE_OK' would be `sqlite-ok'.

  [www.sqlite.org] is always a good source of information, especially
  [An Introduction to the SQLite C/C++ Interface] and [C/C++ API
  Reference].


[SQlite3 constants] <https://www.sqlite.org/rescode.html>

[www.sqlite.org] <https://www.sqlite.org>

[An Introduction to the SQLite C/C++ Interface]
<https://www.sqlite.org/cintro.html>

[C/C++ API Reference] <https://www.sqlite.org/c3ref/intro.html>

1.5.1 sqlite3-open
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-open "/path/to/data-file" flag1 flag2 ...)
  └────
  Open the database file and return a database handle.

  This function calls [sqlite3_open_v2()] internally and raises
  `db-error' in case of error.

  *flag1*, *flag2*…. will be ORed together.


[sqlite3_open_v2()] <https://www.sqlite.org/c3ref/open.html>


1.5.2 sqlite3-close
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-close database-handle)
  └────
  Close the database file.


1.5.3 sqlite3-prepare
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-prepare database-handle sql-statement)
  └────
  Compile the supplied SQL statement and return a statement handle.

  This function calls [sqlite3_prepare_v2()] internally and raises
  'sql-error in case of error.


[sqlite3_prepare_v2()] <https://www.sqlite.org/c3ref/prepare.html>


1.5.4 sqlite3-finalize
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-finalize statement-handle1 statement-handle2 ...)
  └────
  Destroy prepared statements.


1.5.5 sqlite3-step
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-step statement-handle)
  └────
  Execute a prepared SQL statement. Some of the return codes are:

  `sqlite-done' - the statement has finished executing successfully.

  `sqlite-row' - if the SQL statement being executed returns any data,
  then `sqlite-row' is returned each time a new row of data is ready for
  processing by the caller.


1.5.6 sqlite3-changes
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-changes database-handle)
  └────
  Return the number of rows modified (for update/delete/insert
  statements)


1.5.7 sqlite3-reset
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-reset statement-handle)
  └────
  Reset a prepared statement. Call this function if you want to re-bind
  the statement to new variables, or to re-execute the prepared
  statement from the start.


1.5.8 sqlite3-last-insert-rowid
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-last-insert-rowid database-handle)
  └────
  Retrieve the last inserted rowid (64 bit).

  Notes: Beware that Emacs only supports integers up to 61 bits.


1.5.9 sqlite3-get-autocommit
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-get-autocommit database-handle)
  └────
  Return 1 / 0 if auto-commit mode is ON / OFF.


1.5.10 sqlite3-exec
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-exec database-handle sql-statements &optional callback)
  └────
  The Swiss Army Knife of the API, you can execute multiple SQL
  statements (separated by ";") in a row with just one call.

  The callback function, if supplied, is invoked for *each row* and
   should accept 3 parameters:
  1. the first parameter is the number of columns in the current row;
  2. the second parameter is the actual data (as a list strings or nil
     in case of NULL);
  3. the third one is a list of column names.

  To signal an error condition inside the callback, return `nil'.
  `sqlite3_exec()' will stop the execution and raise `db-error'.

  Raises `db-error' in case of error.

  An example of a callback:
  ┌────
  │ (defun print-row (ncols data names)
  │   (cl-loop for i from 0 to (1- ncols) do
  │ 	   (message "[Column %d/%d]%s=%s" (1+ i) ncols (elt names i) (elt data i)))
  │   (message "--------------------")
  │   t)
  │ 
  │ (sqlite3-exec dbh "select * from table_a; select * from table b"
  │ 	      #'print-row)
  └────
  More examples:
  ┌────
  │ ;; Update/delete/insert
  │ (sqlite3-exec dbh "delete from table") ;; delete returns no rows
  │ 
  │ ;; Retrieve the metadata of columns in a table
  │ (sqlite3-exec dbh "pragma table_info(table)" #'print-row)
  └────


1.5.11 sqlite3-bind-*
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-bind-text statement-handle column-no value)
  │ (sqlite3-bind-int64 statement-handle column-no value)
  │ (sqlite3-bind-double statement-handle column-no value)
  │ (sqlite3-bind-null statement-handle column-no)
  └────
  The above four functions bind values to a compiled SQL statements.

  Please note that column number starts from 1, not 0!
  ┌────
  │ (sqlite3-bind-parameter-count statement-handle)
  └────
  The above functions returns the number of SQL parameters of a prepared
  statement.


1.5.12 sqlite3-bind-multi
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-bind-multi statement-handle &rest params)
  └────
  `sqlite3-bind-multi' binds multiple parameters to a prepared SQL
  statement. It is not part of the official API but is provided for
  convenience.

  Example:
  ┌────
  │ (sqlite3-bind-multi stmt 1234 "a" 1.555 nil) ;; nil for NULL
  └────


1.5.13 sqlite3-column-*
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  These column functions are used to retrieve the current row of the
  result set.

  ┌────
  │ (sqlite3-column-count statement-handle)
  └────
  Return number of columns in a result set.  #+END_SRCe1
  (sqlite3-column-type statement-handle column-no) #+END_SRC Return the
  type (`sqlite-integer', `sqlite-float', `sqlite3-text' or
  `sqlite-null') of the specified column.

  Note: Column number starts from 0.
  ┌────
  │ (sqlite3-column-text statement-handle column-no)
  │ (sqlite3-column-int64 statement-handle column-no)
  │ (sqlite3-column-double statement-handle column-no)
  └────
  The above functions retrieve data of the specified column.
  ┌────
  │ (sqlite3-column-name statement-handle column-no)
  └────
  This function returns the column name of the specified column.

  Note: You can call `sqlite3-column-xxx' on a column even if
  `sqlite3-column-type' returns `sqlite-yyy': the SQLite3 engine will
  perform the necessary type conversion.

  Example:
  ┌────
  │ (setq stmt (sqlite3-prepare dbh "select * from temp"))
  │ (while (= sqlite-row (sqlite3-step stmt))
  │ 	(let ((name (sqlite3-column-text stmt 0))
  │ 	      (age (sqlite3-column-int64 stmt 1)))
  │       (message "name: %s, age: %d" name age)))
  └────


1.5.14 sqlite3-fetch
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-fetch statement-handle) ;; returns a list such as (123 56 "Peter Smith" nil)
  └────
  `sqlite3-fetch' is not part of the official API but provided for
  convenience. It retrieves the current row as a list without having to
  deal with sqlite3-column-* explicitly.


1.5.15 sqlite3-fetch-alist
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-fetch-alist statement-handle)
  └────
  `sqlite3-fetch-alist' is not part of the official API but provided for
  convenience. It retrieves the current row as an alist in the form of
  `(("col_name1" . value1) ("col_name2" . value2) ..)'


1.6 Transaction Support
───────────────────────

  Use `sqlite3-exec' to start, commit and rollback a transaction:
  ┌────
  │ (sqlite3-exec dbh "begin")
  │ (sqlite3-exec dbh "commit")
  │ (sqlite3-exec dbh "rollback")
  └────
  See Error Handling below on how to use the [condition-case] form to
  handle rollback.


[condition-case]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Handling-Errors.html>


1.7 Error Handling
──────────────────

  Currently two error symbols are defined in `sqlite3.el':
  1. `sql-error' is raised by `sqlite3-prepare'
  2. `db-error' is raised by `sqlite3-open' and `sqlite3-exec'

  ┌────
  │ (condition-case db-err
  │     (progn
  │       (sqlite3-exec dbh "begin")
  │       (sqlite3-exec dbh "update temp set a = 1 where b = 2")
  │       (sqlite3-exec dbh "commit"))
  │   (db-error
  │    (message "Symbol:%s, Message:%s, Error Code:%d" (elt db-err 0) (elt db-err 1) (elt db-err 2))
  │    (sqlite3-exec dbh "rollback")))
  └────
  `db-err' is a list containing the error symbol (`db-error' or
  `sql-error'), an error message and finally an error code returned from
  the corresponding SQLite C API.


1.8 Note on Garbage Collection
──────────────────────────────

  Since Emacs's garbage collection is non-deterministic, it would be a
  good idea to manually free database/statement handles once they are
  not needed.


1.9 Known Problems
──────────────────

  • SQLite3 supports 64 bit integers but Emacs integers are only 61
    bits.
  For integers > 61 bits you can retrieve them as text as a workaround.
  • BLOB and TEXT columns with embedded NULLs are not supported.


1.10 License
────────────

  The code is licensed under the [GNU GPL v3].


[GNU GPL v3] <https://www.gnu.org/licenses/gpl-3.0.html>


1.11 Contributors
─────────────────

  • [Jonas Bernoulli] - Melpa package
  • @reflektoin
  • @yasuhirokimura


[Jonas Bernoulli] <https://github.com/tarsius>


1.12 Changelog
──────────────

  *v0.16 - 2022-05-01*
  • Fixed a bug in `sqlite3-bind-multi'

  *v0.15 - 2020-09-16*
  • Fixed a bug in `sqlite3-bind-multi' under Emacs 27.1

  *v0.14 - 2020-07-08*
  • Added sqlite3.el (melpa)

  *v0.13 - 2020-04-20*
  • Rewrote README in .org format

  *v0.12 - 2019-05-12*
  • `sqlite3-fetch-alist' added
  • Fixed a compilation problem on macOS Mojave

  *v0.11 - 2017-09-14*
  • `sqlite3-finalize' now accepts multiple handles.

  *v0.1 - 2017-09-04*
  • Emacs Lisp code removed. The package is now pure C.

  *v0.0 - 2017-08-29*
  • Fixed a memory leak in `sql_api_exec()'
  • Changed `sqlite3_close()' to `sqlite3_close_v2()' in
    `sqlite_api_close()'
  • Better error handling: Error code is returned along with error
    message


1.13 Useful Links for Writing Dynamic Modules
─────────────────────────────────────────────

  • <https://phst.github.io/emacs-modules>
  • <http://nullprogram.com/blog/2016/11/05/>
