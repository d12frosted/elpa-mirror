Provides an alternative git-grep based project search using git
grep as an alternative to `vc-git-grep' and various ripgrep and
silver searcher alternatives.  `git grep' is noticeably faster than
find+grep, and comes with git, so it's always available without
additional dependencies.  Where `vc-git-grep' includes a number of
prompts for various options (including extension's and project
path), these commands default to searching all files in the
repository or directory tree and work with a single command.

I use the following configuration to add key bindings for these
grep operations:

  (use-package git-grep
    :commands (git-grep git-grep-repo)
    :bind (("C-c g g" . git-grep)
           ("C-c g r" . git-grep-repo)))
