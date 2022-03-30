This package provides a way to initiate ssh sessions within Emacs
and have directory tracking automatically set up for editing files
with TRAMP.  No configuration is required on the remote host.

Currently this is designed to work with a bash shell on the remote
host, however with a little work this could be changed to allow
different shells via a per-host configuration.

The ideas presented here and various bits of code within were
lifted directly from http://www.emacswiki.org/emacs-se/AnsiTermHints.
Consider the editors of that page as contributors to this package.
