
Auto Virtualenv is a powerful Emacs package for Python developers, offering
automatic virtual environment management based on the directory of the current
project. This tool simplifies working across multiple Python projects by
dynamically detecting and activating virtual environments, reducing the need
for manual configuration.

It integrates seamlessly with `lsp-mode` and `pyright`, optionally reloading
the LSP workspace upon environment activation to maintain accurate imports and
environment settings. Auto Virtualenv identifies Python projects using a
customizable set of markers (e.g., `setup.py`, `pyproject.toml`) and supports
common virtual environment locations, both local and global (e.g., `~/.pyenv/versions/`).

Features:
- **Automatic Virtual Environment Detection and Activation**: Based on project root,
  auto-virtualenv locates and activates virtual environments in either a local
  project directory or in specified global directories.
- **LSP Reload Support**: With `lsp-mode` or `pyright`, optionally reload the LSP workspace
  on environment changes to keep code assistance up-to-date.
- **Modeline Integration**: Displays the active environment in the modeline. When no
  environment is active, "Venv: N/A" is shown.
- **Configurable and Extensible**: Users can add directories for environment searches, set
  custom project markers, and control verbosity for debugging.

Usage:
1. Add `auto-virtualenv` to your `load-path` and enable it with `auto-virtualenv-setup`.
2. Configure `auto-virtualenv-global-dirs`, `auto-virtualenv-python-project-files`,
   and `auto-virtualenv-reload-lsp` as needed.
3. Use it with project management packages like `projectile` or independently.

See the README for detailed setup and configuration examples.
