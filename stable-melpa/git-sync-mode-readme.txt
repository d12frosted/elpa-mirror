This package provides `git-sync-mode`, a minor mode that
automatically and asynchronously synchronizes your local Git
repository with its upstream remote each time you save a file.

The synchronization workflow is as follows:
1. Stage and commit any local changes.
2. Fetch the latest updates from the remote.
3. Analyze the state relative to the upstream branch.
4. Automatically push, fast-forward, or rebase to fully sync.

To ensure safety, `git-sync-mode` will only activate in repositories
whose paths are included in the `git-sync-allow-list`.  It also includes
safeguards to prevent execution if the repository is in a special state
(e.g., during a merge or rebase) or if it is locked.
