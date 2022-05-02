Provides the `py-autopep8-buffer' command, which uses the external "autopep8"
tool to tidy up the current buffer according to Python's PEP8.

; Usage


To automatically apply when saving a python file, use the
following code:

  (add-hook 'python-mode-hook 'py-autopep8-mode)

To customize the behavior of "autopep8" you can set the
`py-autopep8-options' e.g.

  (setq py-autopep8-options '("--max-line-length=100" "--aggressive"))
