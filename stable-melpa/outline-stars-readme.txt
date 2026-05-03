`outline-stars' provides `outshine'-convention star headings (;; * , ;; ** ,
## * , etc.) using the built-in `outline-minor-mode'.  It is a lightweight,
modern replacement for `outshine' that attempts to solve the same problems
in fewer lines on a stable core.

Features:
  - Comment-aware heading detection using `comment-start' and `comment-add'
  - Per-level fontification via `outline-stars-level-N' faces
  - Optional overline on heading lines (top-level only, or all levels)
  - `imenu' integration for heading navigation
  - Subtree promote/demote that optionally updates all child headings
  - Global visibility cycling (folded → content → show-all)
  - Startup visibility state (folded, content, show-all) per-buffer or per-mode
  - Alphabetical sorting of sibling headings
  - Section numbering (0, 0.1, ... or 1, 1.1, ...) with insert/strip/auto
  - Scoped numbering: whole buffer, current subtree, or active region
  - Automatic TAB cycling on headings via `outline-minor-mode-cycle'
  - Installs an `outline-regexp'-driven `outline-search-function' (Emacs 29+)
  - Runs on `after-change-major-mode-hook' to override mode-specific defaults

Usage:
  (require 'outline-stars)
  (outline-stars-mode 1)

Or with use-package:
  (use-package outline-stars
    :config (outline-stars-mode 1))

Set `outline-stars-section-comments' to nil for classic outshine
behavior (;; *, ## *, # *, // *).
