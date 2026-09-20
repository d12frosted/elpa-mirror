`git-modeline-mode' is a global minor mode that prepends a colored
mark to `mode-line-format' in every buffer visiting a file tracked
by, or living inside, a git repository.  The color of the mark tells
the git status of that file at a glance:

  GreenYellow  up to date        yellow  staged
  tomato       modified          blue    added
  red          deleted           purple  unmerged
  gray         untracked

Usage:

  (require 'git-modeline)
  (git-modeline-mode 1)

The mark is refreshed when a file is visited and after each save.
`git-modeline-decoration' selects how it is drawn: a large dot (the
default), a small dot, a status letter, a colored status letter, or
any function of one argument returning a mode-line construct.

The status collection code is derived from git-emacs
(https://github.com/tsgates/git-emacs), reduced to what the modeline
display needs.
