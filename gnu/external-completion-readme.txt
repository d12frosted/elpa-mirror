Written by Stefan Monnier circa 2016.  Variants of this code have
been working stably in SLY and other packages for a long time.

The `external' completion style is used with a "programmable
completion" table that gathers completions from an external tool
such as a shell utility, an inferior process, an http server.

The table and external tool are fully in control of the matching of
the pattern string to the potential candidates of completion.  When
`external' is in use, the usual styles configured by the user or
other in `completion-styles' are ignored.

This compromise is for speed: all other styles need the full data
set to be available in Emacs' addressing space, which is often slow
if not completely unfeasible.

To make use of the `external' style the function
`external-completion-table' should be used.  See its docstring.