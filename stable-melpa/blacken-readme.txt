
Blacken uses black to format a Python buffer.  It can be called
explicitly on a certain buffer, but more conveniently, a minor-mode
'blacken-mode' is provided that turns on automatically running
black on a buffer before saving.

Installation:

Add blacken.el to your load-path.

To automatically format all Python buffers before saving, add the
function blacken-mode to python-mode-hook:

(add-hook 'python-mode-hook 'blacken-mode)
