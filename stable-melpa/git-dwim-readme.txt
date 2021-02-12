
This file provides context-aware git commands.
Currently only `git-branch-next-action'.

`git-branch-next-action' does typical branch handling.
   * If current branch is master: switch to other or new branch.
   * If current branch is not master: switch to other branch or merge this branch to master.
   * If merge is failed: continue merging (You have to resolve conflict merker)
