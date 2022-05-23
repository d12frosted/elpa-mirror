The detached package allows users to run shell commands detached from
Emacs.  These commands are launched in sessions, using the program
dtach[1].  These sessions can be easily created through the command
`detached-shell-command', or any of the commands provided by the
`detached-shell', `detached-eshell' and `detached-compile' extensions.

When a session is created, detached makes sure that Emacs is attached
to it the same time, which makes it a seamless experience for the
users.  The `detached' package internally creates a `detached-session'
for all commands.

[1] https://github.com/crigler/dtach
