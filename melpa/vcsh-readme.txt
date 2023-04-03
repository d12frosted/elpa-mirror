Original idea by Jonas Bernoulli (see the first two links below).

This library only provides basic "enter" functionality
(`vcsh-link', `vcsh-unlink') and a few convenience commands
(`vcsh-new' to init a repo and add files to it,
`vcsh-write-gitignore').

For Magit integration there's magit-vcsh.el as a separate add-on
library.

Please note that this library works by creating a regular file
named ".git" inside $VCSH_BASE directory (typically $HOME) and does
not remove this file automatically, so don't be surprised if your
shell suddenly behaves as after "vcsh enter" when inside that
directory.  You can use `vcsh-unlink' or simply remove the file to
get rid of it.

Cf. also:

https://github.com/magit/magit/issues/2939
https://github.com/magit/magit/issues/460
https://github.com/vanicat/magit/blob/t/vcsh/magit-vcsh.el

Corrections and productive feedback appreciated, publicly
(<public@smrk.net>, inbox.smrk.net) or in private.
