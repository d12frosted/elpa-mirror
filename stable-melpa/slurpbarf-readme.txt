Slurpbarf a library for slurping and barfing, or ingesting and
emitting, expressions in the spirit of Paredit.  The behaviour of
commands is not exactly identical to that in Paredit: in
particular, negative arguments are handled differently in
Slurpbarf.

Supported major modes are Lisp Data mode and nXML mode; however,
the commands should mostly work also in C mode and others; a global
minor mode is provided.

A command for splicing expressions, `slurpbarf-splice', is included
but not bound to any key.
