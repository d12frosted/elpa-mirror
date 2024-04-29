Use mise (https://mise.jdx.dev/) to set environment variables on a
per-buffer basis.  This means that when you work across multiple
projects which have `.envrc` files, all processes launched from the
buffers "in" those projects will be executed with the environment
variables specified in those files.  This allows different versions
of linters and other tools to be installed in each project if
desired.

Enable `global-mise-mode' late in your startup files.  For
interaction with this functionality, see `mise-', and the
commands `mise-reload'.
