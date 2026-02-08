A lightweight GitHub CLI (gh) integration for Magit.
Provides commands to list and checkout pull requests
using the `gh` CLI tool (https://cli.github.com).

Usage:
  Press ",'" in Magit buffers to open the GitHub CLI menu.

Setup with use-package:

  (use-package magit-gh
    :ensure t
    :after magit)

To use a custom keybinding, set the variable before
the package loads:

  (use-package magit-gh
    :ensure t
    :after magit
    :init
    (setq magit-gh-key ";"))

To increase the number of PRs fetched (default 30):

  (use-package magit-gh
    :ensure t
    :after magit
    :custom
    (magit-gh-pr-limit 50))

Requires: gh must be installed and authenticated.
Run `gh auth login` to authenticate.
See: https://cli.github.com
