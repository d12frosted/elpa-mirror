
Isortify uses isort to format a Python buffer.  It can be called
explicitly on a certain buffer, but more conveniently, a minor-mode
'isortify-mode' is provided that turns on automatically running isort
on a buffer before saving.

Installation:

Add isortify.el to your load-path.

To automatically format all Python buffers before saving, add the function
isortify-mode to python-mode-hook:

(add-hook 'python-mode-hook 'isortify-mode)
