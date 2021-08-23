Query workspace symbol from eglot using consult.

This package provides a single command `consult-eglot-symbols' that uses the
lsp workspace/symbol procedure to get a list of symbols exposed in the current
workspace. This differs from the default document/symbols call, that eglot
exposes through imenu, in that it can present symbols from multiple open files
or even files not indirectly loaded by an open file but still used by your
project.

This code was partially adapted from the excellent consult-lsp package.
