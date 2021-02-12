This package provides very basic support for TopGit.

  TopGit is a patch queue manager that aims to make handling
  of large amounts of interdependent topic branches easier.

For information about TopGit see https://github.com/greenrd/topgit.

When `magit-topgit-mode' is turned on then the list of TopGit
topics is displayed in the status buffer.  While point is on such
a topic it can checked out using `RET' and discarded using `k'.
Other TopGit commands are available from the TopGit popup on `T'.

TopGit popup on `T' shadows default magit-notes-popup on `T'.
To rebind magit-notes-popup on `O':

  (with-eval-after-load 'magit
    (define-key magit-mode-map "O" 'magit-notes-popup)
    (magit-change-popup-key 'magit-dispatch-popup :action ?T ?O))

To enable the mode in a particular repository use:

  cd /path/to/repository
  git config --add magit.extension topgit

To enable the mode for all repositories use:

  git config --global --add magit.extension topgit

To enable the mode globally without dropping to a shell:

  (add-hook 'magit-mode-hook 'magit-topgit-mode)
