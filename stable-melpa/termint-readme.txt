termint provides a flexible way to define and manage interactions
with REPLs and CLI apps running inside a terminal emulator backend
within Emacs.  It allows you to easily configure how Emacs
communicates with different REPLs, leveraging the capabilities of
fully-featured terminal emulators like `term', `vterm', or `eat'.

Instead of relying on Emacs’s built-in “dumb” terminal
(`comint-mode'), termint runs REPLs in a full terminal emulator,
enabling features like bracketed paste mode, proper rendering, and
potentially advanced interaction for complex terminal applications.

It facilitates the creation of custom REPL commands
tailored to each defined REPL, with features including starting
session, sending code, and hiding REPL windows.  This is useful for
integrating terminal-based REPLs with Emacs efficiently.
