context-clues provides a convenient transient menu for copying various file,
buffer, and code context information to the kill ring.  Useful for e.g.
communicating context with LLMs.

Usage:
  M-x context-clues

This opens a transient menu with options for copying file names, paths,
line numbers, function names, git branches, and more.  Each entry shows
a live preview of the value it would copy.  Options that are not
applicable to the current buffer will be grayed out.

See the README for the full list of features and keybindings.
