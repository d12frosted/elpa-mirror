
`pyimpsort.el' sort the python imports of a file.
Currently uses [pyimpsort.py](pyimpsort.py) to process the way to sort python
imports.

; Setup
Add the following snippet to your `init.el':

    (require 'pyimpsort)
    (eval-after-load 'python
      '(define-key python-mode-map "\C-c\C-u" #'pyimpsort-buffer))

; Troubleshooting:
+ **Doesn't sort correctly third party libraries**

  `pyimpsort.el' tries to identify the third party libraries if are installed
  in in the PYTHONPATH, if a package is not installed it is assumed that
  belongs to the application.
  `pyimpsort.el' also tries to identify if a python virtualenv
  is activated.

; Related projects:
+ [isort][] ([emacs integration](https://github.com/paetzke/py-isort.el))

[isort]: https://github.com/timothycrosley/isort
