Provides commands, which use the external "yapf"
tool to tidy up the current buffer according to Python's PEP8.

To automatically apply when saving a python file, use the
following code:

  (add-hook 'python-mode-hook 'py-yapf-enable-on-save)
