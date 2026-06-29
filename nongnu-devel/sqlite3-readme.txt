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

  The current version is v0.18.

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

  It's been tested on macOS (Catalina), CentOS 7 and MS-Windows 11.


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

  The module is built using the `make all' command by default. To
  customize the build process, you can override this behavior by setting
  the `SQLITE3_API_BUILD_COMMAND' environment variable.


[Melpa] <https://melpa.org/#/sqlite3>


1.4.2 Elpa
╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ $ git clone https://github.com/pekingduck/emacs-sqlite3-api
  │ $ cd emacs-sqlite3-api
  │ $ make module
  └────

  A tar archive called `sqlite3-X.Y.tar' will be created. Do a `M-x
  package-install-file' in Emacs to install that tar archive and you're
  all set.

  For Homebrew users on MacOS or Linux:
  ┌────
  │ $ make HOMEBREW=1
  └────
  to build the module against sqlite3 installed by Homebrew.

  If you have sqlite3 installed in a nonstandard location:
  ┌────
  │ $ make INC=/path/to/sqlite3/include LIB="-L/path/to/sqlite3/lib -lsqlite3"
  └────


1.4.3 Straight.el
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you would like to use this library with [the straight emacs package
  manager], you will need git pre-installed.  The following are example
  snippets of elisp that can be included in your init file for using
  straight.


[the straight emacs package manager]
<https://github.com/radian-software/straight.el>

◊ 1.4.3.1 Setting up the build environment

  For those where sqlite3 C library is installed to a non-standard
  directory, such as with an installation via homebrew, you may need to
  add the path to the `libsqlite3.so' to your `LD_LIBRARY_PATH'
  environment variable with `setenv'.

  ┌────
  │ (defconst sqlite-lib-dir
  │   ;; This example executes 'brew --prefix sqlite' to find the current installation path dynamically
  │   (concat
  │    (string-trim (shell-command-to-string "brew --prefix sqlite"))
  │    "/lib"))
  │ 
  │ ;; Set LD_LIBRARY_PATH in Emacs' environment
  │ (setenv "LD_LIBRARY_PATH" 
  │ 	(if-let (current-path (getenv "LD_LIBRARY_PATH"))
  │ 	    (concat sqlite-lib-dir ":" current-path)
  │ 	  sqlite-lib-dir))
  └────


◊ 1.4.3.2 Installing via Straight without the use-package macro

  We need to modify `straight-default-files-directive' with an explicit
  list of `:files' or our shared object that we compile with `make' will
  not be linked into the emacs load path.  Hence, we add to the
  `:defaults', the shared library file extensions with a globbing
  pattern.

  Homebrew users will want to uncomment the `:pre-build' directive so
  that straight runs `make' in a way that finds brew's sqlite
  installation directory.

  ┌────
  │ (straight-use-package
  │    '(sqlite3
  │       :host github
  │       :repo "pekingduck/emacs-sqlite3-api"
  │       :files (:defaults "*.dll" "*.dylib" "*.so")
  │       ;; :pre-build ("env" "HOMEBREW=1" "make" "all")
  │     ))
  │ (load-library "sqlite3")
  └────


◊ 1.4.3.3 Straight with the use-package macro

  One can optionally use straight with the use-package macro to get all
  of the configuration - including homebrew - handled in one block:

  ┌────
  │ (use-package sqlite3
  │   :init
  │   (defconst sqlite-lib-dir
  │   ;; Execute 'brew --prefix sqlite' to find the current installation path
  │ 	(concat
  │ 	 (string-trim (shell-command-to-string "brew --prefix sqlite"))
  │ 	 "/lib"))  
  │   (setenv "LD_LIBRARY_PATH" 
  │     (if-let (current-path (getenv "LD_LIBRARY_PATH"))
  │ 	(concat sqlite-lib-dir ":" current-path)
  │       sqlite-lib-dir))
  │   ;; Customize straight.el's build process for the sqlite3 module
  │   :straight
  │   (sqlite3 
  │    :host github
  │    :repo "pekingduck/emacs-sqlite3-api"
  │    :files (:defaults "*.dll" "*.dylib" "*.so")
  │    :pre-build ("env" "HOMEBREW=1" "make" "all"))
  │   :config
  │   (load-library "sqlite3")
  │ )
  └────

  The `:init' section runs before the package is loaded into emacs, so
  it is great for handling things the OS dynamic loader might want
  defined.


1.4.4 Manual Installation
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ $ git clone https://github.com/pekingduck/emacs-sqlite3-api
  │ $ cd emacs-sqlite3-api
  │ $ make
  │ $ cp sqlite3.el sqlite3-api.so /your/elisp/load-path/
  └────


1.4.5 Removal
╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you installed manually, just remove `sqlite3.el' and
  `sqlite3-api.so' from your load path. Otherwise, do `M-x
  package-delete' to remove the sqlite3 package.


1.4.6 Note on Package Update
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


1.5 Testing
───────────

  The tests can be run with the [Eldev] build tool

  ┌────
  │ # from source
  │ eldev test
  │ # or as a compiled package
  │ eldev -p test
  └────

  See [Eldev documentation] for more information.


[Eldev] <https://github.com/emacs-eldev/eldev>

[Eldev documentation] <https://emacs-eldev.github.io/eldev/>


1.6 API
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

1.6.1 sqlite3-open
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-open "/path/to/data-file" flag1 flag2 ...)
  └────
  Open the database file and return a database handle.

  This function calls [sqlite3_open_v2()] internally and raises
  `db-error' in case of error.

  *flag1*, *flag2*…. will be ORed together.


[sqlite3_open_v2()] <https://www.sqlite.org/c3ref/open.html>


1.6.2 sqlite3-close
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-close database-handle)
  └────
  Close the database file.


1.6.3 sqlite3-prepare
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-prepare database-handle sql-statement)
  └────
  Compile the supplied SQL statement and return a statement handle.

  This function calls [sqlite3_prepare_v2()] internally and raises
  'sql-error in case of error.


[sqlite3_prepare_v2()] <https://www.sqlite.org/c3ref/prepare.html>


1.6.4 sqlite3-finalize
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-finalize statement-handle1 statement-handle2 ...)
  └────
  Destroy prepared statements.


1.6.5 sqlite3-step
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-step statement-handle)
  └────
  Execute a prepared SQL statement. Some of the return codes are:

  `sqlite-done' - the statement has finished executing successfully.

  `sqlite-row' - if the SQL statement being executed returns any data,
  then `sqlite-row' is returned each time a new row of data is ready for
  processing by the caller.


1.6.6 sqlite3-changes
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-changes database-handle)
  └────
  Return the number of rows modified (for update/delete/insert
  statements)


1.6.7 sqlite3-reset
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-reset statement-handle)
  └────
  Reset a prepared statement. Call this function if you want to re-bind
  the statement to new variables, or to re-execute the prepared
  statement from the start.


1.6.8 sqlite3-last-insert-rowid
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-last-insert-rowid database-handle)
  └────
  Retrieve the last inserted rowid (64 bit).

  Notes: Beware that Emacs only supports integers up to 61 bits.


1.6.9 sqlite3-get-autocommit
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-get-autocommit database-handle)
  └────
  Return 1 / 0 if auto-commit mode is ON / OFF.


1.6.10 sqlite3-exec
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


1.6.11 sqlite3-bind-*
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


1.6.12 sqlite3-bind-multi
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


1.6.13 sqlite3-column-*
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


1.6.14 sqlite3-fetch
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-fetch statement-handle) ;; returns a list such as (123 56 "Peter Smith" nil)
  └────
  `sqlite3-fetch' is not part of the official API but provided for
  convenience. It retrieves the current row as a list without having to
  deal with sqlite3-column-* explicitly.


1.6.15 sqlite3-fetch-alist
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (sqlite3-fetch-alist statement-handle)
  └────
  `sqlite3-fetch-alist' is not part of the official API but provided for
  convenience. It retrieves the current row as an alist in the form of
  `(("col_name1" . value1) ("col_name2" . value2) ..)'


1.7 Transaction Support
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


1.8 Error Handling
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


1.9 Note on Garbage Collection
──────────────────────────────

  Since Emacs's garbage collection is non-deterministic, it would be a
  good idea to manually free database/statement handles once they are
  not needed.


1.10 Known Problems
───────────────────

  • SQLite3 supports 64 bit integers but Emacs integers are only 61
    bits.
  For integers > 61 bits you can retrieve them as text as a workaround.
  • BLOB and TEXT columns with embedded NULLs are not supported.


1.11 License
────────────

  The code is licensed under the [GNU GPL v3].


[GNU GPL v3] <https://www.gnu.org/licenses/gpl-3.0.html>


1.12 Contributors
─────────────────

  • [Jonas Bernoulli] - Melpa package
  • @reflektoin
  • @yasuhirokimura
  • @ikappaki - added GitHub CI Actions (0aa2b03)


[Jonas Bernoulli] <https://github.com/tarsius>


1.13 Changelog
──────────────

  *v0.18 - 2023-11-24*
  • Module is now loaded after compilation.
  • GitHub CI Actions added

  *v0.17 - 2023-03-15*
  • Added 28.2 to regression tests

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


1.14 Useful Links for Writing Dynamic Modules
─────────────────────────────────────────────

  • <https://phst.github.io/emacs-modules>
  • <http://nullprogram.com/blog/2016/11/05/>
