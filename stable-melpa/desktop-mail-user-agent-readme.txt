If you're running Emacs as a desktop application on the X Window
System, MacOS, or Windows, this package launches the desktop
environment's default mail app to write mail messages from Emacs.
The `compose-mail' command, and other commands using it indirectly,
are affected.

To install, call `desktop-mail-user-agent`.  It sets
`mail-user-agent' and stores the old `mail-user-agent' to use as a
fallback for complex mail-sending tasks that require editing the
mail message in an Emacs buffer.

Currently this package only concerns sending mail.  Reading mail via
`read-mail-command' is not affected.
