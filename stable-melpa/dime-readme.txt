This file contains extensions for programming in Open Dylan.
The main features are:

* A socket-based communication/RPC interface between Emacs and
  Dylan, enabling introspection and remote development.

* The `dime-mode' minor-mode complementing `dylan-mode'.  This new
  mode includes many commands for interacting with the Open Dylan
  process.

* A Dylan debugger written in Emacs Lisp.  The debugger pops up
  an Emacs buffer similar to the Emacs/Elisp debugger.

* A Open Dylan inspector to interactively look at run-time data.

* Trapping compiler messages and creating annotations in the source
  file on the appropriate forms.

In order to run Dime, a supporting Dylan server called Swank is
required.
