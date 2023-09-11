This package is used for bundling related git-worktrees from multiple
repositories together.  This helps switch quickly between repositories and
ensure you're on the correct branch.  When you're done with your changes, you
can use the repositories in the workspace and know which ones were modified
to simplify the process of getting the changes merged in together.

Additionally, git metadata (the =.git= directory) is shared between all
projects.  You can stash, pop, and pull changes in from the same repository in
other workspaces thanks to the power of git-worktrees.


;; Terminology:

Bare
  A bare repository used as a source to create a 'PROJECT's git-worktree.

Project
  A git-worktree checked out from a 'BARE' stored in a 'WORKSPACE'.

Workspace
  A collection of 'PROJECT's created from 'BARE's.
