
`pyimpsort.el' sort the python imports of a file.
Currently uses [pyimpsort.py](pyimpsort.py) to process the way to sort python
imports.

; Setup
Add the following snippet to your `init.el':

    (require 'pyimpsort)
    (eval-after-load 'python
      '(define-key python-mode-map "\C-c\C-u" #'pyimpsort-buffer))
