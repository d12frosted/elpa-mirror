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


;; Structure:

The workspaces directory is structured as such:

`treebundel-workspace-root' (default: "~/workspaces/")
   |
   L workspace1
   |    L project-one   (branch: "feature/workspace1")
   |    L project-two   (branch: "feature/workspace1")
   |    L project-three (branch: "feature/workspace1")
   |
   L workspace2
        L project-one   (branch: "feature/workspace2")
        L project-two   (branch: "feature/workspace2")
        L project-three (branch: "feature/workspace2")


;; Quick start:

Assuming default configuration, the following will create a bare clone of the
provided repo URL to '~/workspaces/.bare/<repo-name>.git', then create and
open a worktree for a new branch called 'feature/<workspace>'.

1. Interactively call `treebundel-add-project'.
2. Enter name for the new (or existing) workspace.
3. Select '[ clone ]'.
4. Enter the URL to clone for the repository to be added to the workspace.


;; Configuration:

`treebundel-branch-prefix'
 Default: 'feature/'

This is probably the most subjective variable you'd want to customize.  With
its default value, when you add a project to a workspace named, for example,
'new-protocol', the new project will be checked out to a new branch called
'feature/new-protocol'.

`treebundel-workspace-root'
 Default: '~/workspaces/'

This one is also very subjective.  It's where all of your workspaces will
exist on your file-system.

`treebundel-project-open-function'
 Default: `project-switch-project'

This is the function called when a project is opened.  You could also just
make this `find-file' to just open the file instantly or any other function
that takes a file path.

`treebundel-before-workspace-open-functions'
`treebundel-before-project-open-functions'
`treebundel-after-project-open-hook'
`treebundel-after-workspace-open-hook'

These hooks are called before or after a project or workspace is
opened.  `treebundel-before-workspace-open-functions' receives the
name of the workspace to be opened as a single argument and
`treebundel-before-project-open-functions' receives the workspace
and project name opened.

;; Usage:

The following functions are the commands you should use (and
probably bind) to make use of this package.

`treebundel-open'
  Open a project in a workspace.

`treebundel-open-project'
  Open other project within current workspace.

`treebundel-add-project'
  Add a project to a workspace.

`treebundel-remove-project'
  Remove a project from a workspace.  This will check if the project
  has any changes before removing it.

`treebundel-delete-workspace'
  Delete a workspace.  This will also remove all projects in a
  workspace if they don't have any changes.
