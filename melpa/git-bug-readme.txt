A minimal interface to git-bug (https://github.com/git-bug/).

This package provides a =completing-read= menu to match existing bugs
and another menu to act on a bug.

Good entrypoints and canidates for assigned keybindings are
  * =git-bug-menu=
  * =git-bug-new-from-line=

Usage:
(use-package git-bug
  :bind
  ("C-c b m" . git-bug-menu)
  ("C-c b c" . git-bug-new-from-line))
