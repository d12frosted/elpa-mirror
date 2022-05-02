`consult-ls-git' allows to quickly select a file from a git repository
or act on a stash.  It provides a consult multi view of files
considered by 'git status', stashes as well as all tracked files.
Alternatively you can narrow to a specific section via the shortcut key:
  s: Status
  z: Stash
  f: Tracked Files

If `default-directory' is inside a git repository, it will use this
repository.  Otherwise `consult-ls-git-project-prompt-function' is
used to select the project directory.

Each view also has a standalone command in case that is preferable:
  consult-ls-git-status
  consult-ls-git-stash
  consult-ls-git-tracked-files
