
Vulpea is a note management library for Org mode that maintains its
own SQLite database for efficient querying and organization.

Key features:
- Fast note lookup via SQLite database with automatic sync
- Rich note structure: titles, aliases, tags, links, properties, metadata
- Flexible querying by tags, links, properties, dates, and more
- Metadata system using Org description lists
- Note creation with customizable templates
- Selection interface with filtering and alias expansion

Quick start:
  (setq vulpea-directory "~/org/")
  (vulpea-db-sync-start)

Main entry points:
- `vulpea-find' - find and open a note
- `vulpea-insert' - insert a link to a note
- `vulpea-create' - create a new note
- `vulpea-db-query' - query notes with a predicate
- `vulpea-select' - select a note with completion

See https://github.com/d12frosted/vulpea for documentation.
