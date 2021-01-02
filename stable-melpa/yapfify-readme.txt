
Yapfify uses yapf to format a Python buffer. It can be called explicitly on a
certain buffer, but more conveniently, a minor-mode 'yapf-mode' is provided
that turns on automatically running YAPF on a buffer before saving.

Installation:

Add yapfify.el to your load-path.

To automatically format all Python buffers before saving, add the function
yapf-mode to python-mode-hook:

(add-hook 'python-mode-hook 'yapf-mode)
