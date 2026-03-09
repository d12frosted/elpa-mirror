This package can be used to ensure that named blocks are executed
when org-mode files are visited, or saved after edits.

This is designed to allow you to update all tables, automatically,
or perform other similar utility actions.

To use these facilities define blocks like so in your org-mode files:

#+NAME: org-eval-load
#+BEGIN_SRC emacs-lisp :results output silent
  (message "I like cakes when documents load.")
#+END_SRC

#+NAME: org-eval-save
#+BEGIN_SRC emacs-lisp :results output silent
  (message "I like a party, just before a save!")
#+END_SRC

By default `org-mode' will prompt you to confirm that you want
execution to happen, we use `org-eval-prefix-list' to enable
whitelisting particular prefix-directories, which means there is
no need to answer `y` to the prompt.

So as a second line of defense we require you to explicitly
name the blocks that you trust in your configuration, like so:

  (use-package org-eval
    :after org
    :config
     (setq org-eval-prefix-list (list (expand-file-name "~/Private/"))
           org-eval-loadblock-name "skx-loadblock"
           org-eval-saveblock-name "skx-saveblock")
     (org-eval-global-mode 1))

This means blocks named `skx-loadblock' will be executed when files
are loaded from beneath `~/Private', and on-save the block named skx-saveblock
will be executed.

I hope that this means there is no realistic way for malicious files
to execute arbitrary code upon your system;  The files would have to
have the correct named blocks, and be saved within a trusted directory
before any possible malicious code could be executed.

