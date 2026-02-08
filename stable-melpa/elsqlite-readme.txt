ELSQLite is a native Emacs SQLite browser that provides a unified
interface for exploring and editing SQLite databases.

The core philosophy is "turtles all the way down" -- everything is a SQL
query, and the UI is a convenient way to build/modify that query.

Features:
- Two-panel layout: results view (top) and SQL editor (bottom)
- Bidirectional sync between SQL panel and data view
- Schema browser for exploring database structure
- Table browser with pagination and sorting
- Automatic edit vs browse mode detection
- SQL completion with context awareness
- Query history

Usage:
  M-x elsqlite RET /path/to/database.db RET

See README.md for detailed documentation.
