
`sudo' support in Emacs.
Currently it has two features.

* `sudoedit' command opens files as root using sudoedit program.
  This command needs emacsserver or gnuserv.
  Try M-x server-start or M-x gnuserv-start first.
  Be sure to you can run `sudoedit FILE' in shell.

* `sudo' support in shell execution in Emacs.
  In executing sudo shell command, password prompt is appeared if needed.
  * M-x compile
  * M-x grep
  * M-!
  * M-|
  * M-&
  * M-x executable-interpret
