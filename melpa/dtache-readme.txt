The dtache package allows users to run shell commands detached from
Emacs.  These commands are launched in sessions, using the program
dtach[1].  These sessions can be easily created through the command
`dtache-shell-command', or any of the commands provided by the
`dtache-shell', `dtache-eshell' and `dtache-compile' extensions.

When a session is created, dtache makes sure that Emacs is attached
to it the same time, which makes it a seamless experience for the
users.  The `dtache' package internally creates a `dtache-session'
for all commands.

[1] https://github.com/crigler/dtach
