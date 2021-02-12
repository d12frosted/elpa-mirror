
This file implements communcation with the KWin window manager from
KDE. This is not really a repl, as KWin does not keep the state
between scripts.

This file contains

  * a major mode for displaying output and errors.
  * a minor mode for sending code portions or whole files from
    other buffers to KWin, `kwin-minor-mode'.
