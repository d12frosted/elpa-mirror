Eglot ("Emacs Polyglot") is an Emacs LSP client that stays out of
your way.

Typing M-x eglot should be enough to get you started, but here's a
little info (see the accompanying README.md or the URL for more).

M-x eglot starts a server via a shell command guessed from
`eglot-server-programs', using the current major mode (for whatever
language you're programming in) as a hint.  If it can't guess, it
prompts you in the minibuffer for these things.  Actually, the
server does not need to be running locally: you can connect to a
running server via TCP by entering a <host:port> syntax.

If the connection is successful, you should see an `eglot'
indicator pop up in your mode-line.  More importantly, this means
that current *and future* file buffers of that major mode *inside
your current project* automatically become \"managed\" by the LSP
server.  In other words, information about their content is
exchanged periodically to provide enhanced code analysis using
`xref-find-definitions', `flymake-mode', `eldoc-mode',
`completion-at-point', among others.

To "unmanage" these buffers, shutdown the server with
M-x eglot-shutdown.

To start an eglot session automatically when a foo-mode buffer is
visited, you can put this in your init file:

  (add-hook 'foo-mode-hook 'eglot-ensure)
