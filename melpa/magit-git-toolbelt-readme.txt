A Magit interface for Vincent Driessen's git-toolbelt:
https://github.com/nvie/git-toolbelt

Usage:
  M-x magit-git-toolbelt or press "\" in Magit buffers (customizable)

To change the keybinding (to "."):

  (use-package magit-git-toolbelt
    :ensure t
    :custom
    (magit-git-toolbelt-key "."))

git-toolbelt must be installed and available in your PATH.
See: https://github.com/nvie/git-toolbelt#installation
