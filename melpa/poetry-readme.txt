This package offers an interface to poetry (https://poetry.eustace.io/),
a Python dependency management and packaging command line tool.

Poetry.el uses transient to provide a magit-like interface. The
entry point is simply: `poetry'

Poetry.el also provides a global minor mode that automatically
activates the associated virtualenv when visiting a poetry project.
You can activate this feature with `poetry-tracking-mode'.
