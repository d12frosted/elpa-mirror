Specialized compile mode for pylint.  You may want to add the
following to your init.el:

  (autoload 'pylint "pylint")
  (add-hook 'python-mode-hook 'pylint-add-menu-items)
  (add-hook 'python-mode-hook 'pylint-add-key-bindings)

There is also a handy command `pylint-insert-ignore-comment' that
makes it easy to insert comments of the form `# pylint:
ignore=msg1,msg2,...'.
