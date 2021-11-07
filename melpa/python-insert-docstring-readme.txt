This package can automatically generate function docstrings in Python
according to the Google style guide available at this URL:

https://google.github.io/styleguide/pyguide.html#383-functions-and-methods

The text gets automatically indented and split on multiple lines.

In order to use this package, you can set a custom keybinding in your
~/.emacs file such as:

(defun set-python-keybindings ()
  (local-set-key (kbd "C-c i") 'python-insert-docstring-with-google-style-at-point)
  )
(add-hook 'python-mode-hook 'set-python-keybindings)

Now, in a python file, place the cursor on a function, type `C-c i` and
follow the instructions.
