
This package simplifies shell management and sudo access by providing
the following commands.

`better-shell-shell'
--------------------

Cycle through existing shell buffers, in order of recent use.  If
there are no shells, one is created.

With C-u prefix arg, invoke `better-shell-for-current-dir'.

`better-shell-for-current-dir'
------------------------------

Bring up a shell on the same host and in the same directory as the
current buffer, choosing an existing shell if possible.  The shell
chosen is guaranteed to be idle (not currently running a command).  It
first looks for an idle shell that is already in the buffer's
directory.  If none is found, it looks for another idle shell on the
same host as the buffer.  If one is found, that shell is selected and
automatically placed into the buffer's directory with a `cd` command.
Otherwise, a new shell is created on the same host and in the same
directory as the buffer.

`better-shell-remote-open'
--------------------------

Open a shell on a remote server, allowing you to choose from any host
you've previously logged into (uses your ~/.ssh/known_hosts file) or
enter a new host.  With C-u prefix arg, get sudo shell.

`better-shell-sudo-here'
--------------------------

Reopen the current file, directory, or shell as root.
