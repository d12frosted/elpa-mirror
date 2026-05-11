This package provides a preset for Eglot to work with Python files,
including support for PEP-723 script metadata and project detection.
It configures the LSP server (ty, basedpyright, pyrefly, or zuban) and handles
environment synchronization for uv-managed scripts.

Prerequisites:

- Install uv
- Install ty (>= v0.0.8), basedpyright, pyrefly, or zuban as a Python language server
- Download this file and add it to the load path

Quick start (package-vc):

  (use-package eglot-python-preset
    :vc (:url "https://github.com/mwolson/eglot-python-preset")
    :custom
    (eglot-python-preset-lsp-server 'ty)) ; or 'basedpyright, 'pyrefly,
                                           ; 'zuban, or 'rass

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
