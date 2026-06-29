This package allows GnuPG passphrase to be prompted through the
minibuffer instead of graphical dialog.

To use, add "allow-emacs-pinentry" to "~/.gnupg/gpg-agent.conf",
reload the configuration with "gpgconf --reload gpg-agent", and
start the server with M-x pinentry-start.

The actual communication path between the relevant components is
as follows:

  gpg --> gpg-agent --> pinentry --> Emacs

where pinentry and Emacs communicate through a Unix domain socket
created at:

  ${TMPDIR-/tmp}/emacs$(id -u)/pinentry

under the same directory which server.el uses.  The protocol is a
subset of the Pinentry Assuan protocol described in (info
"(pinentry) Protocol").

NOTE: As of August 2015, this feature requires newer versions of
GnuPG (2.1.5+) and Pinentry (0.9.5+).