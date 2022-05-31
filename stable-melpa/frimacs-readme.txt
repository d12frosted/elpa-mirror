The `frimacs' package is intended to make it easier to work with
and understand the FriCAS computer algebra system.  It implements
four different major modes for the Emacs text editor:

  1. frimacs-process-mode: for interaction with a running FriCAS
     process.

  2. frimacs-help-mode: for displaying help information about the
     FriCAS system.

  3. frimacs-input-mode: for editing FriCAS script (.input) files.

  4. frimacs-spad-mode: for editing FriCAS library code written in
     the SPAD language.

These modes enable syntax highlighting to display package, domain &
category names (and their abbreviations) in distinct colours, and
give quick access to popup buffers displaying summary information
about these types and their operations.

Once the package is installed, files ending in .input, and .spad
are put into the appropriate mode, and there is an "M-x
frimacs-run-fricas" command available to start an interactive
FriCAS session.  Look into the Frimacs menu that appears in these
buffers to discover further capabilities of the system.

Note: this Emacs package (frimacs) can be considered to be the
successor to the axiom-environment package.  Currently frimacs
offers essentially the same functionality as axiom-environment did,
but with all function and variable names changed appropriately.
This has been done in a fit of honesty, to acknowledge the fact
that nearly all development has been done with FriCAS from day one,
and that it should be FriCAS that takes centre stage in future
developments.
