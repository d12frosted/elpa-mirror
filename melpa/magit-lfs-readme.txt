The `magit-lfs' is plugin for `magit', most famous Emacs-Git integration.
This plugin is `magit' integrated frontend for Git LFS,
Git Large File System.

To use this plugin,

1. Install git-lfs.

2. Use following codes in your Emacs setting.

- For Vanilla Emacs (After install magit, magit-lfs):

  (require 'magit-lfs)

- For Emacs with `use-package' (After load magit, dash):

  (use-package magit-lfs
     :ensure t
     :pin melpa)

- For Emacs with `req-package' (After install dash):

  (req-package magit-lfs
     :loader :elpa
     :pin melpa
     :require (magit))

For more detail information, please see README.md
