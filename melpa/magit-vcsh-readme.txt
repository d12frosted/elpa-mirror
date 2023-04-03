This library provides a global minor mode `magit-vcsh-hack-mode'
that advises Magit functions so that `magit-list-repositories' and
`magit-status' work with vcsh repos.  `magit-vcsh-status' works
even without enabling the minor mode.

`magit-vcsh-status' is also added to `vcsh-after-new-functions' to
open Magit status buffer on the new repo upon creation.

See also the commentary in vcsh.el for more information.

Corrections and productive feedback appreciated, publicly
(<public@smrk.net>, inbox.smrk.net) or in private.
