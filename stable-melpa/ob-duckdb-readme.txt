
This package provides Org Babel integration for DuckDB, an in-process
analytical SQL database engine.

DuckDB (https://duckdb.org/) combines analytical performance with a
familiar SQL interface. ob-duckdb brings these capabilities directly into
Org documents for data exploration and literate analytics.

Basic usage:

    #+begin_src duckdb
    SELECT * FROM read_csv('data.csv') LIMIT 10;
    #+end_src

With persistent database:

    #+begin_src duckdb :db /path/to/database.duckdb
    CREATE TABLE analysis AS SELECT * FROM read_parquet('large.parquet');
    SELECT COUNT(*) FROM analysis;
    #+end_src

Asynchronous execution (requires session):

    #+begin_src duckdb :session work :async yes
    SELECT * FROM huge_table WHERE complex_condition;
    #+end_src

The package supports:
- Session-based execution for stateful workflows
- Multiple output formats (box, csv, json, markdown, etc.)
- Variable substitution from Org elements
- DuckDB dot commands for configuration
- Automatic result truncation for large outputs
- Progress monitoring for long-running queries
- FIFO queue for multiple async executions per session

Block tracking is optional and disabled by default:

    ;; Minimal mode (default) - only async execution tracking
    (require 'ob-duckdb)

    ;; Full tracking mode - execution history and debugging
    (require 'org-duckdb-blocks)
    (setq org-duckdb-blocks-enable-tracking t
          org-duckdb-blocks-visible-properties nil) ; invisible by default
    (org-duckdb-blocks-setup)

With tracking disabled, async executions still work correctly via
exec-id embedded in result placeholders. Full tracking adds:
- Execution history (`org-duckdb-blocks-recent')
- Block registry (`org-duckdb-blocks-list')
- Navigation commands (`org-duckdb-blocks-navigate-recent')

Property storage modes (only when tracking enabled):
- Invisible (default): Text properties, no document pollution
- Visible: #+PROPERTY: lines for inspection

Key commands:
- `org-babel-duckdb-create-session' - Start a session
- `org-babel-duckdb-display-sessions' - Show active sessions
- `org-babel-duckdb-show-queue' - Monitor async execution queue
- `org-babel-duckdb-cancel-execution' - Cancel async execution in queue
