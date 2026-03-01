This package adds clickable inline buttons to smerge-mode conflict markers,
similar to VS Code's CodeLens feature.  When a merge conflict is detected,
buttons appear above the conflict markers allowing one-click resolution.

Available actions:
- Accept Current: keep the current branch's changes
- Accept Incoming: keep the incoming branch's changes
- Accept Both: keep both changes
- Compare: open ediff to compare versions

The buttons appear automatically when smerge-mode is active.

Usage:
  (add-hook 'smerge-mode-hook #'conflict-buttons-mode)

Or enable globally:
  (conflict-buttons-global-mode 1)
