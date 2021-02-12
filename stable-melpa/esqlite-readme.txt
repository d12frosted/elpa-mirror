esqlite.el is a implementation to handle sqlite database.
 (version 3 or later)

Following functions are provided:
* Read sqlite row as list of string.
* Async read sqlite row as list of string.
* sqlite process with being stationed
* Construct sqlite SQL.
* Escape SQL value to construct SQL
* Some of basic utilities.
* NULL handling (denote as :null keyword)

Following environments are tested:
* Windows7 cygwin64 with fakecygpty (sqlite 3.8.2)
* Windows7 native binary (Not enough works)
* Debian Linux (sqlite 3.7.13)

## Install:

Please install sqlite command. (http://www.sqlite.org/)
Please install this package from MELPA. (http://melpa.org/)

## Usage:

See the online document:
https://github.com/mhayashi1120/Emacs-esqlite
