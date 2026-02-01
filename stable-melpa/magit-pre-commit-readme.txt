This package provides magit integration for pre-commit, the framework
for managing and maintaining multi-language pre-commit hooks.

Features:
- Run pre-commit on staged files or all files
- Run specific hooks with completion
- Install and update pre-commit hooks
- Status section showing running/failed hooks

The integration activates when both conditions are met:
- The `pre-commit' executable is available in PATH
- A `.pre-commit-config.yaml' file exists in the project root

To enable, add to your init file:
  (add-hook 'magit-mode-hook #'magit-pre-commit-mode)
