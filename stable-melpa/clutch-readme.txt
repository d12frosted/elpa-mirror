Interactive database client with native and JDBC backends.

Provides:
- `clutch-mode': SQL editing major mode (derived from `sql-mode')
- `clutch-repl': REPL via `comint-mode'
- Query execution with horizontally scrollable result tables
- Object discovery and completion

Entry points:
  M-x clutch-mode      — open a SQL editing buffer
  M-x clutch-repl      — open a REPL
  Open a .mysql file   — activates clutch-mode automatically
