Provides project-level Overleaf integration:

- clone a full Overleaf project to a local Git repository
- push committed local changes to Overleaf and pull remote updates back
- detect remote divergence and resolve it with normal Git merges

Conflict resolution intentionally happens in Git, not ediff.  When
both local and remote changed, `git-overleaf-pull' merges the
downloaded remote snapshot into the current branch and leaves
conflicts to Magit or plain Git.
