A major mode for Pyfun (https://github.com/simontreanor/Pyfun), an
F#-inspired, functional-first language that compiles to readable Python.

Provides syntax highlighting, comment support, and (on Emacs 29+) eglot
integration with the language server bundled in the Pyfun compiler:
install it with `pip install pyfun-lang', which puts `pyfun' on PATH, and
run M-x eglot in a Pyfun buffer (or enable `eglot-ensure' via
`pyfun-mode-hook') for diagnostics, hover types and effects,
go-to-definition, rename, and completion.
