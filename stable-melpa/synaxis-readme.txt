synaxis (Greek σύναξις, "gathering") is a small feed reader for
Emacs.  It reads RSS, Atom, and JSON feeds and stores them in
SQLite -- the single source of truth for all displayed state.

Top-level commands:
  M-x synaxis            open the entry list buffer
  M-x synaxis-add-feed   register a new feed URL
  M-x synaxis-update     fetch all feeds asynchronously
  M-x synaxis-remove-feed delete a feed and its entries
