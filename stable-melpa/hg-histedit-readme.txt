This package assists the user in editing the list of commits to be
rewritten during an interactive histedit.

When the user initiates histedit, this mode is used to let the user
edit, mess, pick, base, drop, fold, and roll commits.

This package provides the major-mode `hg-histedit-mode' which adds
some additional keybindings.

  C-c C-c  Tell Hg to make it happen.
  C-c C-k  Tell Hg that you changed your mind, i.e. abort.

as well as shortkey commands to modify the changeset.

Example:
----------------------------------------------------------------------------
# Edit history between 567c7a9b5d19 and 105332c82b1a
#
# Commits are listed from least to most recent
#
# You can reorder changesets by reordering the lines
#
# Commands:
#
#  e, edit = use commit, but stop for amending
#  m, mess = edit commit message without changing commit content
#  p, pick = use commit
#  b, base = checkout changeset and apply further changesets from there
#  d, drop = remove commit from history
#  f, fold = use commit, but combine it with the one above
#  r, roll = like fold, but discard this commit's description and date
#
----------------------------------------------------------------------------

Many thanks for the original `git-rebase' written and maintained by Phil
Jackson and Jonas Bernoulli.
