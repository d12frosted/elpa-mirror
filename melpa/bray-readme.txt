Bray provides a blank-slate for users to define their own modal editing workflow.

Key features:

- A way for users to define custom states (such as `normal`, `insert`, `special` etc).
- Per *state* settings such as cursor, key-maps & enter/exit hooks.
- Enter/exit hooks can be used to further refine the behavior.

The user may define any number of states - which may even be buffer-local,
allowing for context-dependent modal editing behavior.
