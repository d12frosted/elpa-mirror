Org-Babel support for evaluating SQL using sql-mode.

Usage:

Enter an Org SRC block that specifies sql-mode.

  #+BEGIN_SRC sql-mode
  <enter query here>
  #+END_SRC

You can also type "<Q[TAB]" to expand a template that does this
(change `org-babel-sql-mode-template-selector' to use a key other
than "Q" to select the template).

Although all the statements in the block will be executed, only the
results from executing the final statement will be returned.

Supported params.

":product productname" -- name of the product to use when evaluating
    the SQL.  Must be a value in `sql-product-alist'.  The default is
    given by the entry for ":product" in
    `org-babel-default-header-args:sql-mode'.

":session sessionname" -- name of the session to use when
    evaluating the SQL.  All SQL blocks that share the same product
    and session settings will be executed in the same comint
    buffer.  If blank then the session name is "none".

Using Org property syntax you can set these on a per-file level with
a line like:

    #+PROPERTY: header-args:sql-mode :product sqlite
    #+PROPERTY: header-args:sql-mode+ :session mysession

Or in a per-heading property drawer

    :PROPERTIES:
    :header-args:sql-mode :product sqlite
    :header-args:sql-mode+ :session mysession
    :END:

(note the "+" on the second lines to append to the value -- you could
also place those on one line).

Supported hooks.

org-babel-sql-mode-pre-execute-hook

    Hook functions take STATEMENTS, a list of SQL statements to
    execute, and PROCESSED-PARAMS.  A hook function should return
    nil, or a new list that replaces STATEMENTS.  Hooks run until
    the first one returns success.

    Typical use: Modifying STATEMENTS depending on values in
    PROCESSED-PARAMS.

org-babel-sql-mode-post-execute-hook

    Hook functions take no arguments, and execute with the current
    buffer set to the buffer that contains the output from the
    query (so variables like `sql-product' are in scope).  Each
    hook function can make any changes it wants to the contents of
    the buffer.

    Typical use: Cleaning up unwanted output from the buffer.

Recommended user configuration:

;; Disable evaluation confirmation checks for sql-mode.
(setq org-confirm-babel-evaluate
      (lambda (lang body)
        (not (string= lang "sql-mode"))))

Known problems / future work.

[note: these problems might be due to my cursory familiarity with
 sql-mode]

* Calls `sql-product-interactive' from `sql-mode' to start a
  session.  This then calls `pop-to-buffer' which displays the
  buffer.  This is unwanted, so the code currently temporarily
  redfines `pop-to-buffer'.  It would be better if `sql-mode'
  had a function that silently created the comint buffer.

* The strategy for sending data to the comint process is
  suboptimal.

  Broadly, there seem to be two ways to do it.

  1. Keep the entered query as a multi-line string, and try and
     use `sql-send-region'.  But `sql-send-region' can't redirect
     into another buffer.

  2. (current code) Calls `sql-redirect' to send the query and
     redirect the results to the session buffer.  But
     `sql-redirect' appears to want each statement to be a single
     line.  So the current code naively assumes it can split the
     string on ';', remove "--.*$", and then replace newlines with
     spaces to construct an acceptable statement.  This works, but
     is fragile.

* Does nothing with Org :vars blocks.  I don't have a solid use for
  them yet.

* Would be nice if there was a configuration option to include all
  the results, not just the result from the last statement.
  Requires changes to `sql-mode'.

* Some mechanism to translate between the SQL results tables and
  Org table format would be interesting.

* Doesn't support header params to specify things like the database
  user, password, connection params, and so on.  That's probably best
  left delegated to `sql-mode' and the various product feature options.
