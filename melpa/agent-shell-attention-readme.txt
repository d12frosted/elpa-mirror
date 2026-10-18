`agent-shell-attention-mode' instruments the `agent-shell' prompt
flow to keep track of buffers that are waiting for user input.  It
displays a clickable `AS:n' indicator in the mode line, provides a
command `agent-shell-attention-jump' to visit pending buffers, and
can optionally issue notifications via a user-defined function.

It also includes a renderer for an `AS:n/m' pending/active indicator.
`agent-shell-attention-jump-idle' returns to an idle shell, or offers
completion with a prefix argument.  `agent-shell-attention-dashboard'
lists all sessions with their status and last activity.

Enable with (agent-shell-attention-mode).
