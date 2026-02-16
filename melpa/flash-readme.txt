Fast navigation using labels assigned to search matches.
Similar to flash.nvim for Neovim.

Features:
- Incremental search with instant feedback
- Smart labels that skip conflicting characters
- Multi-window search support
- Autojump when single match
- Fold-aware navigation

Usage:
  M-x flash-jump

Or bind to a key:
  (global-set-key (kbd "s-j") #'flash-jump)
