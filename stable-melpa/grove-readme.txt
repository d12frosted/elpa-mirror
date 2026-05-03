Grove is a simple, fast note-taking mode for Emacs that provides an
Obsidian-like experience for org files.  One keybinding opens a full
UI with a file tree sidebar and note editing area.

Features:
- Built-in file tree sidebar
- Quick note capture
- Wikilinks with backlinks (ripgrep-powered, no database)
- Daily notes
- Full-text and tag search (Consult integration optional)
- Graph view (Graphviz-based)
- Inbox review for triaging untagged notes

Usage:
  (setq grove-directory "~/notes/")
  (global-grove-mode 1)   ; auto-enable grove-mode in vault files
  (grove-open)
