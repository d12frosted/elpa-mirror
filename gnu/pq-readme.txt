An Emacs 25 module for accessing PostgreSQL via the libpq client
library.

Using libpq for client connections has various advantages over the
wire-protocol speaking pure elisp implementations.  For example, it has
better performance and supports all features of the protocol like full
TLS support and new authentication methods like scram-sha-256.

It doesn't expose many libpq features yet, but what's there should be
crash-safe no matter what you do in the lisp world.  I've been using it
for three years now for reading mail through my custom Gnus backend
without incidents.  If you make it crash, please report.


1 Basic usage
═════════════

  ┌────
  │ ELISP> (setq *pq* (pq:connectdb "dbname=andreas"))
  │ #<user-ptr ptr=0x55b466c02780 finalizer=0x7f7d50112236>
  │ ELISP> (pq:query *pq* "select version()")
  │ ("PostgreSQL 9.6.7 on x86_64-pc-linux-gnu, compiled by gcc (Debian 6.3.0-18) 6.3.0 20170516, 64-bit")
  │ ELISP> (pq:query *pq* "create table local_variables(name text, value text)")
  │ nil
  │ ELISP> (dolist (el (buffer-local-variables))
  │ 	 (pq:query *pq* "insert into local_variables values ($1, $2)"
  │ 		   (car el) (cdr el)))
  │ nil
  │ ELISP> (pq:query *pq* "select name, length(value) from local_variables where value ~ 'mode'")
  │ (["major-mode" 24]
  │  ["change-major-mode-hook" 86]
  │  ["hi-lock-mode-major-mode" 24]
  │  ["eldoc-mode-major-mode" 24]
  │  ["font-lock-major-mode" 24]
  │  ["font-lock-mode-major-mode" 24])
  └────


2 Error Handling
════════════════

  `pq' raises SQL errors as error signal `pq:error'.  This provides the
  [SQLSTATE] error code in an additional string in the error data list.
  For example, you can reliably catch unique violations like this:

  ┌────
  │ (condition-case err (pq:query *pq* "insert into t values (666)")
  │   (pq:error
  │    (if (string= "23505" (nth 2 err))
  │        (progn
  │ 	 (message "Caught a unique violation"))
  │      ;; re-throw anything else
  │      (signal (car err) (cdr err)))))
  └────


[SQLSTATE]
<https://www.postgresql.org/docs/current/errcodes-appendix.html>


3 Conversion of data types from SQL to Emacs Lisp
═════════════════════════════════════════════════

  `pq' converts bigints and numerics your queries return to lisp floats
  because they don't fit into a lisp integer.  This looses precision on
  big values.  If you need the full precision, cast them to `text' and
  use, e.g., `calc-eval' to do arbitrary precision things with them.
  All other data types are returned as utf-8 strings.


4 Conversion of data types from Emacs Lisp to SQL
═════════════════════════════════════════════════

  Strings and the query text itself is converted to utf-8 by the module
  interface.  If this conversion fails, the behavior is undefined by the
  module interface.  If you want to send strings that are not valid
  utf-8, you need to work around this.  For example, I'm using code like
  the following to store raw bytes into a table with a `bytea' column:

  ┌────
  │ (pq:query *con*
  │   "insert into t (blob) values (decode($1, 'base64'))"
  │   (base64-encode-string my-random-bytes))
  └────


  Any non-string parameter to pq:query is turned into an emacs string
  using `prin1-to-string' first.  This works quite well to store
  arbitrary lisp data and read it back with `read'.  All other aspects
  of `prin1-to-string' apply too.  For example, when `print-length' or
  `print-level' are set to non-nil, these would be applied as well.


5 Notifications
═══════════════

  After a [`LISTEN'] statement, PostgreSQL will deliver notifications
  asynchronously over the connection.  Since the emacs-module interface
  does not allow for asynchronous callbacks, you have to check for these
  periodically after a `LISTEN' statement by calling `pq:notifies'.
  Calling it will not cause any traffic on the connection itself.

  See the testsuite <./test.el> for more implemented features.

  <https://api.travis-ci.org/anse1/emacs-libpq.svg>


[`LISTEN'] <https://www.postgresql.org/docs/current/sql-listen.html>
