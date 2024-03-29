This package offers an interface to poetry (https://python-poetry.org/),
a Python dependency management and packaging command line tool.

poetry.el uses transient to provide a magit-like interface. The
entry point is simply: `poetry'

poetry.el also provides a global minor mode that automatically
activates the associated virtualenv when visiting a poetry project.
You can activate this feature with `poetry-tracking-mode'.
