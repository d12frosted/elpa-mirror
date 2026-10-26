Front-end for the fz-index dynamic module: fuzzy search and open
any file in a project, responsive at Chromium scale (400k+ files).

Usage: M-x fz-index-open-file
  Type to narrow, C-n/C-p (or M-<down>/M-<up>) to move,
  RET to open, C-u RET to open in another window,
  M-RET to insert the path into the buffer you came from,
  C-o to jump between the minibuffer and the results buffer
  (in the results buffer, RET opens the file on the current
  line; isearch works there too), C-g to quit.

The native module:

fz-index needs the fz-index-core dynamic module.  On first use it
is installed automatically (`fz-index-module-auto-install',
default t): a prebuilt binary matching your platform is downloaded
from the project's GitHub Releases and verified against the SHA-256
checksum published with the release (Linux/macOS/Windows, x86_64
and aarch64); failing that, the bundled fz-index.c is compiled
with a local gcc/clang (only emacs-module.h and a C99 compiler are
needed).  With `fz-index-module-auto-install' nil, a missing
module just raises an error.

Security and trust model:

Using this package loads native code into your Emacs process.  The
prebuilt binaries are built by the project's CI from the committed
fz-index.c and verified against the SHA-256 in the release's
checksums.txt.  That protects against a corrupted or truncated
download, but it is not a defense against a compromised release:
anyone who can publish to the repository or its CI can ship a
binary together with a matching checksum.  The alternative is to
compile the bundled fz-index.c yourself, which runs a compiler you
already trust on source you can read; to take only that path, set
`fz-index-module-auto-install' to nil.

This file is part of an independent project; it is NOT a
contribution to GNU Emacs.
