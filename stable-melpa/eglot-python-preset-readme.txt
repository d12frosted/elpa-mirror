This package provides a preset for Eglot to work with Python files,
including support for PEP-723 script metadata and project detection.
It configures the LSP server (ty or basedpyright) and handles environment
synchronization for uv-managed scripts.

Prerequisites:

- Install uv
- Install ty (>= v0.0.8) or basedpyright as a Python language server
- Download this file and add it to the load path

Quick start:

  (require 'eglot-python-preset)
  (setopt eglot-python-preset-lsp-server 'ty)
  ;; or
  ;; (setopt eglot-python-preset-lsp-server 'basedpyright)
  (eglot-python-preset-setup)

After that, opening Python files will automatically start the LSP server using
Eglot and handle PEP-723 magic tags within files.

Workspace configuration (basedpyright):

To customize basedpyright settings, set `eglot-workspace-configuration'
before calling `eglot-python-preset-setup'.  Your settings will be merged
with PEP-723 script configurations (which add :python :pythonPath).

Example:

  (setopt eglot-workspace-configuration
          '(:basedpyright.analysis
            (:autoImportCompletions :json-false
             :typeCheckingMode "basic")))
  (eglot-python-preset-setup)
