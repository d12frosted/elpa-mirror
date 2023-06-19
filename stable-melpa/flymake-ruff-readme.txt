Usage:
  (require 'flymake-ruff)
  (add-hook 'python-mode-hook #'flymake-ruff-load)

Or, with use-package:
  (use-package flymake-ruff
    :ensure t
    :hook (python-mode . flymake-ruff-load))
