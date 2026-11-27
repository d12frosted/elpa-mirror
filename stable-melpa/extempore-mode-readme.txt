A major mode for editing Extempore code (https://extemporelang.github.io).

With Extempore's nREPL transport (the default), the mode starts Eglot with
Extempore's language server, `extempore lsp', which connects to a running
Extempore's nREPL server (found through a .nrepl-port file, else port
7888).  That gives evaluation with each result shown at its form, errors
marked as diagnostics, completion, eldoc from hover, and formatting.

The most important commands are

  C-M-x      `extempore-send-dwim': evaluate the top-level form at point,
             or the region
  C-c C-k    `extempore-send-buffer'
  C-c C-b    `extempore-interrupt'
  C-c C-z    `extempore-switch-to-process-buffer': start Extempore in a
             buffer, or go to it

For an Extempore older than its nREPL server, set `extempore-transport' to
`legacy' and connect to its eval server on port 7099 with C-c C-j.

See README.md for more.
