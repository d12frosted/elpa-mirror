Collect recent git commits across multiple repositories and format
them as org-mode standup notes.  On weekends and Mondays it
automatically looks back to Friday; on other weekdays it looks back
to the previous day.  The list of repositories and the lookback
behavior are configurable.

Usage:
  M-x magit-standup

Customize `magit-standup-repos' to specify which repositories to
scan.  When nil, only the current repository is used.
