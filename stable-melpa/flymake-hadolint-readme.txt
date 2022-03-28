This package provides flymake backend for hadolint, a Dockerfile linter.
To use it with dockerfile-mode, add the following to your init file:

  (add-hook 'dockerfile-mode-hook #'flymake-hadolint-setup)
