Usage:

  (require 'flymake-python-pyflakes)
  (add-hook 'python-mode-hook 'flymake-python-pyflakes-load)

To use "flake8" instead of "pyflakes", add this line:

  (setq flymake-python-pyflakes-executable "flake8")

You can pass extra arguments to the checker program by customizing
the variable `flymake-python-pyflakes-extra-arguments', or setting it
directly, e.g.

  (setq flymake-python-pyflakes-extra-arguments '("--ignore=W806"))

Uses flymake-easy, from https://github.com/purcell/flymake-easy
