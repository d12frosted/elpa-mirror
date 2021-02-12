Provides commands, which use the external "isort" tool
to tidy up the imports in the current buffer.

To automatically sort imports when saving a python file, use the
following code:

  (add-hook 'before-save-hook 'py-isort-before-save)

To customize the behaviour of "isort" you can set the
py-isort-options e.g.

  (setq py-isort-options '("--lines=100"))
