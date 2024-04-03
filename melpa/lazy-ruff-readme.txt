This package provides Emacs commands to format and lint Python code using
the external 'ruff' tool.  It offers functions to format the entire buffer,
specific regions, or Org mode source blocks.

Prerequisites:
- The 'ruff' command-line tool must be installed and available in your
  system's PATH. Please refer to the 'ruff' documentation at:
  https://docs.astral.sh/ruff/installation/

lazy-ruff quickstart with use-package:
(use-package lazy-ruff
  :ensure t
  :bind (("C-c f" . lazy-ruff-lint-format-dwim)) ;; keybinding
  :config
  (lazy-ruff-global-mode t)) ;; Enable the lazy-ruff minor mode globally

For further information on how to use lazy-ruff, please refer to the README at:
https://github.com/christophermadsen/emacs-lazy-ruff
