* What is it?

  Emacs comes with a SQL interpreter which is able to open a connection
  to databases and present you with a prompt you are probably familiar
  with (e.g. `mysql>', `pgsql>', `presto>', etc.). This mode gives you
  the ability to do that for Presto.


* How do I get it?

  The canonical repository for the source code is
  [https://github.com/kat-co/sql-prestodb].

  The recommended way to install the package is to utilize Emacs's
  `package.el' along with MELPA. To set this up, please follow MELPA's
  [getting started guide], and then run `M-x package-install
  sql-presto'.


  [getting started guide] https://melpa.org/#/getting-started


* How do I use it?

  Within Emacs, run `M-x sql-presto'. You will be prompted by in the
  minibuffer for a server. Enter the correct server and you should be
  greeted by a SQLi buffer with a `presto>' prompt.

  From there you can either type queries in this buffer, or open a
  `sql-mode' buffer and send chunks of SQL over to the SQLi buffer with
  the requisite key-chords.


* Contributing

  Please open GitHub issues and issue pull requests. Prior to submitting
  a pull-request, please run `make'. This will perform some linting and
  attempt to compile the package.


* License

  Please see the LICENSE file.
