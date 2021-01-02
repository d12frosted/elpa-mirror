
Helm "Switch-to-REPL" offers the `helm-switch-to-repl' action, a generalized
and extensible version of `helm-ff-switch-to-shell'.  It can be added to
`helm-find-files' and other `helm-type-file' sources such as `helm-locate'.

Call `helm-switch-to-repl-setup' to install the action and bind it to "M-e".

Extending support to more REPLs is easy, it's just about adding a couple of
specialized methods.  Look at the implementation of for `shell-mode' for an
example.
