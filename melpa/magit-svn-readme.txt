This package provides basic support for Git-Svn.

  Git-Svn is a Git command that aims to provide bidirectional
  operation between a Subversion repository and Git.

For information about Git-Svn see its manual page `git-svn(1)'.

If you are looking for native SVN support in Emacs, then have a
look at `psvn.el' and info node `(emacs)Version Control'.

When `magit-svn-mode' is turned on then the unpushed and unpulled
commit relative to the Subversion repository are displayed in the
status buffer, and "N" is bound to a transient command with
suffixes that wrap the `git-svn' subcommands fetch, rebase,
dcommit, branch and tag, as well as a few extras.

To enable the mode in a particular repository use:

  cd /path/to/repository
  git config --add magit.extension svn

To enable the mode for all repositories use:

  git config --global --add magit.extension svn

To enable the mode globally without dropping to a shell:

  (add-hook 'magit-mode-hook 'magit-svn-mode)

This package is unmaintained see the README for more information.
