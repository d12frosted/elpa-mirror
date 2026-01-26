A Magit interface for Vincent Driessen's git-toolbelt:
https://github.com/nvie/git-toolbelt

Usage:
  M-x magit-git-toolbelt or press "\" in Magit buffers (customizable)

Setup with use-package:

  (use-package magit-git-toolbelt
    :ensure t
    :after magit)

To use a custom keybinding (e.g., "."), set the variable before
the package loads:

  (use-package magit-git-toolbelt
    :ensure t
    :after magit
    :init
    (setq magit-git-toolbelt-key "."))

git-toolbelt must be installed and available in your PATH.
See: https://github.com/nvie/git-toolbelt#installation
