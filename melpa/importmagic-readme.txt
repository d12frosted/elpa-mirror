importmagic.el is a package intended to help in the Python
development process by providing a way to fix unresolved imports in
Python buffers, so if you had the following buffer:

os.path.join('path1', 'path2')

importmagic.el will provide you a set of functions that will let
you fix the unresolved 'os' symbol.

The functions can be read on the project's website:

https://github.com/anachronic/importmagic.el

It's worth noting that you will have to install two Python packages
for this to work:

- importmagic
- epc

If you don't have those, importmagic shall gracefully fail and let
you know.
