This package helps synchronizing the recent files list between Emacs
instances.  Without it, each Emacs instance manages its own recent files
list.  The last one to close persistently saves its list into
`recentf-save-file'; all files recently opened by other instances are
overwritten.

With sync-recentf, all running Emacs instances periodically synchronize their
local recent files list with `recentf-save-file'.  This ensures that all
instances share the same list, which is persistently saved across sessions.

`sync-recentf-marker' is always pushed on top of `recentf-list' when it is
synchronized, after a load from `recentf-save-file' or an explicit merge.

All files appearing before `sync-recentf-marker' in `recentf-list' were
visited after the last synchronization, meaning that they should be pushed up
in the next synchronization phase.  Synchronization actually happens at file
save (see `recentf-save-list') or during periodical cleanups (see
`recentf-cleanup')

If you make improvements to this code or have suggestions, please do not
hesitate to fork the repository or submit bug reports on github.  The
repository is at:

    https://github.com/ffevotte/sync-recentf
