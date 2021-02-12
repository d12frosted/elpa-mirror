Run pydoc with counsel.
It use python -m pydoc_utils to generate a list of modules, classes, methods, and functions.
To invalidate the cache after new package installed, run counsel-pydoc with universal arguments.

Usage:
  with virtual env:
    1. pip install pydoc_utils (into a virtualenv)
    2. activate your virtual environment. (pyvenv-activate recommended)
    3. M-x counsel-pydoc
  without virtual env:
   1. sudo pip install pydoc_utils
   2. M-x counsel-pydoc
