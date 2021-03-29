Dime is the Dylan interaction mode for Emacs.  It is essentially an
IDE (integrated development environment) for the Dylan programming
language and the Open Dylan toolchain.

The main features are:

* The `dime-mode' minor-mode.  It augments `dylan-mode' with many
  commands for interacting with Open Dylan.

* The ability to display compiler messages directly at their source
  code locations.

* A debugger running in Emacs, similar to the Emacs Lisp debugger.

* An inspector to interactively look at run-time data.

Dime works by opening a socket between Emacs and Open Dylan and
communicating via the dswank protocol.  Dime traces its history back
to SLIME (the Superior Lisp Interaction Mode for Emacs).
