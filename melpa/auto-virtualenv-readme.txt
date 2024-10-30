
Auto Virtualenv is an Emacs package that automatically activates Python virtual
environments based on the project directory you're working in. It simplifies
switching between Python projects by detecting both local (e.g., `.venv`) and
global (e.g., `~/.pyenv/versions/`) environments. It supports common Python
project files (like `setup.py`, `pyproject.toml`) and can optionally integrate
with `projectile` if installed, without making it a strict dependency.

Features:
- Auto-detects and activates virtual environments based on project root directory.
- Displays active environment in the mode line; shows "Venv: N/A" when none is active.
- Fallback to global virtual environments if no local `.venv` is found.
- Allows users to set custom directories and file markers for project detection.
- Optionally integrates with `projectile` if available for project root detection.

Installation:
- **MELPA**: Once available, use `M-x package-install` and search for `auto-virtualenv`.
- **Straight.el**:
  ```emacs-lisp
  (use-package auto-virtualenv
    :straight (:host github :repo "marcwebbie/auto-virtualenv")
    :config
    (setq auto-virtualenv-verbose t)
    (auto-virtualenv-setup))
  ```
- **use-package** (for users not using `straight.el`):
  ```emacs-lisp
  (use-package auto-virtualenv
    :load-path "path/to/auto-virtualenv.el"
    :config
    (setq auto-virtualenv-verbose t)
    (auto-virtualenv-setup))
  ```

Usage:
Simply open a Python file within a project directory. `auto-virtualenv` will
automatically search for a local virtual environment (e.g., `.venv` in the project
root), falling back to a global directory (such as `~/.pyenv/versions/`) if no local
environment is found. Upon detection, it activates the virtual environment and updates
the mode line to display the environment name.

Customization:
- `auto-virtualenv-global-dirs`: Directories to search for virtual environments by project name.
- `auto-virtualenv-python-project-files`: List of files that identify a Python project.
- `auto-virtualenv-activation-hooks`: Hooks that trigger virtual environment activation.
- `auto-virtualenv-verbose`: Enable verbose output for debugging.

Known Alternatives & Inspiration:
- `pyvenv`: A popular package for managing virtual environments manually.
- `pyenv-mode`: Integrates with `pyenv` to manage Python versions.
- `pipenv.el`: Specific to `pipenv` workflows.
- `projectile`: Project management with extensive file and project navigation features.
