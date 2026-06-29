This module provides a reproducible Gnus installation, including
dummy data, that can be used for Gnus development and testing.
Call `gnus-mock-start' from your currently-running Emacs to start a
new Emacs instance, skipping all user init (ie startup as -Q), but
preloading a mock Gnus installation.  All normal Gnus startup
commands will begin a session within this mock installation.

The developer can also specify a different Emacs executable to
start (for instance, when working on a Git branch checked out in a
worktree).  This is controlled by the `gnus-mock-emacs-program'
option.

The mock session starts with some predefined servers, as well as
some dummy mail data.  At startup, all dummy data is copied into a
temporary directory, which is deleted at shutdown.  The environment
can thus be loaded, tweaked, trashed, and re-loaded with impunity.
To fully restore a clean testing environment, simply quit the Emacs
process and restart it from the parent process by running
`gnus-mock-start' again.  Alternately it's possible to restart "in
place" by calling `gnus-mock-reload', though, depending on what the
developer has gotten up to, this isn't guaranteed to completely
restore the environment.

Users have two options for adding custom configuration to the mock
session:

- `gnus-mock-gnus-file' can be set to a filename, the contents
   of which will be appended to the .gnus.el startup file in the
   mock session.  This code will be executed at Gnus startup.

- `gnus-mock-init-file' should also be a filename, the contents
  of which will be appended to the init.el file that is loaded when
  the child Emacs process starts.

It's possible to compose and send mail in a mock Gnus session; the
mail will be sent using the value of `gnus-mock-sendmail-program'.
If Python is available on the user's system, this option will be
set to a Python program that simply accepts the outgoing mail and
shunts it to the "incoming" mailbox of the pre-defined nnmaildir
server.