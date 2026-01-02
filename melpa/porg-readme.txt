Porg brings Org-mode's structural editing to any programming language
by treating specially-formatted comments as hierarchical headings.

Features:
  - Visual bullets (◉ ○ ●) replace comment markers
  - Optional block backgrounds between sections
  - TAB/S-TAB cycling for folding (like Org-mode)
  - Navigate with C-c C-n/C-c C-p, search with C-c C-j
  - TODO/DONE keywords with M-S-left/M-S-right
  - Promote/demote with M-left/M-right
  - Works with any comment syntax (automatically detected)

Usage:
  (add-hook 'prog-mode-hook #'porg-mode)

Example:
  /// Main Section          <- Level 1 heading
  //// TODO Subsection      <- Level 2 heading
  ///// Implementation      <- Level 3 heading

The number of comment characters determines heading level.
Default base level is 3 (configurable via `porg-base-level').
