Grove is a simple, fast note-taking mode for Emacs that provides an
Obsidian-like experience for a directory of notes.  One keybinding
opens a full UI with a file tree sidebar and note editing area.
Org and Markdown notes can share one vault.

Features:
- Org and Markdown notes side by side in one vault
- Built-in file tree sidebar
- Quick note capture
- Wikilinks with backlinks (ripgrep-powered, no database)
- Daily notes
- Full-text and tag search (Consult integration optional)
- Graph view (Graphviz-based)
- Inbox review for triaging untagged notes

Usage:
  ;;;; Single note location
  (setq grove-directory "~/notes/")
  ;;;; Profile mode for different storage locations.
  (setq grove-profiles
        '((personal :directory "~/remoteFolder/personal")
          (work     :directory "~/localFolder/work")
          (other    :directory "~/otherNotes")))
  (global-grove-mode 1)   ; auto-enable grove-mode in vault files
  (grove-open)
