This package is no longer maintained.

This package provides very basic support for StGit.

  StGit (Stacked Git) is an application that aims to provide a
  convenient way to maintain a patch stack on top of a Git branch.

For information about StGit see http://www.procode.org/stgit.

If you are looking for full fledged StGit support in Emacs, then
have a look at `stgit.el' which is distributed with StGit.

When `magit-stgit-mode' is turned on then the current patch series
is displayed in the status buffer.  While point is on a patch the
changes it introduces can be shown using `RET', it can be selected
as the current patch using `a', and it can be discarded using `k'.
Other StGit commands are available from the StGit popup on `/'.

To enable the mode in a particular repository use:

  cd /path/to/repository
  git config --add magit.extension stgit

To enable the mode for all repositories use:

  git config --global --add magit.extension stgit

To enable the mode globally without dropping to a shell:

  (add-hook 'magit-mode-hook 'magit-stgit-mode)
