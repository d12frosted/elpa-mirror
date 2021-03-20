Have you ever killed a buffer that you might want to leave alive?
Motivation for killing is usually “get out of my way,” and killing may be
not the best choice in some cases.  This package allows us to teach Emacs
which buffers to kill and which to bury alive.

When we want to kill a buffer, it turns out that not all buffers would
like to die in the same way.  To help with that, the package allows us to
specify *how* to kill different kinds of buffers.  This may be especially
useful when a buffer has an associated process.
