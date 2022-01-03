direnv (https://direnv.net/) integration for emacs.

use ‘direnv-update-environment’ to manually update the emacs
environment so that inferior shells, linters, compilers, and test
runners start with the intended environmental variables.

enable the global ‘direnv-mode’ minor mode to do this
automagically upon switching buffers.

use ‘direnv-allow’ to mark a ".envrc" as safe.
