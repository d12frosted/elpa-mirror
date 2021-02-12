[[https://melpa.org/#/emacsql-sqlite3][file:https://melpa.org/packages/emacsql-sqlite3-badge.svg]]
[[https://travis-ci.org/cireu/emacsql-sqlite3][file:https://travis-ci.org/cireu/emacsql-sqlite3.svg?branch=master]]

* Introduction

This is yet another [[https://github.com/skeeto/emacsql][EmacSQL]] backend for SQLite, which use official =sqlite3=
executable to access SQL database.

* Installation

=emacsql-sqlite3= is available on melpa.

* Usage

For Emacs users, please notice that this package won't provide any feature for
convenience. *If you don't sure you need this, you probably don't need this.*

For package developers, this package can be a replacement of [[https://github.com/skeeto/emacsql][emacsql-sqlite]] and
it doesn't require user to have a C compiler, but please read following
precautions.

- You need to install =sqlite3= official CLI tool, 3.8.2 version or above were
  tested, =emacsql-sqlite3= may won't work if you using lower version.

- =sqlite3= CLI tool will load =~/.sqliterc= if presented, =emacsql-sqlite3=
  will get undefined behaviour if any error occurred during the load progress.
  It's better to keep this file empty.

- This package should be compatible with =emacsql-sqlite3= for most cases. But
  foreign key support was disabled by default. To enable this feature, use
  ~(emacsql <db> [:pragma (= foreign_keys ON)])~

The only entry point to a EmacSQL interface is =emacsql-sqlite3=, for more
information, please check [[https://github.com/skeeto/emacsql/blob/master/README.md][EmacSQL's README]].

* About Closql

[[https://github.com/emacscollective/closql][closql]] is using =emacsql-sqlite= as backend, you can use following code to force
closql use =emacsql-sqlite3=.

#+BEGIN_SRC emacs-lisp :results none
(with-eval-after-load 'closql
  (defclass closql-database (emacsql-sqlite3-connection)
    ((object-class :allocation :class))))
#+END_SRC

* Known issue

The tests don't pass under Emacs 25.1 for unknown reason, so we don't support
Emacs 25.1 currently like [[https://github.com/skeeto/emacsql][emacsql-sqlite]]. But any PR to improve this are
welcomed.
