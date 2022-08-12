direnv (https://direnv.net/) integration for Emacs.  See the readme at
https://github.com/wbolster/emacs-direnv for details.

quick usage instructions for those familiar with direnv:

- use ‘direnv-update-environment’ to manually update the Emacs
  environment so that inferior shells, linters, compilers, and test
  runners start with the intended environmental variables.

- enable the global ‘direnv-mode’ minor mode to do this
  automagically upon switching buffers.

- use ‘direnv-allow’ to mark a ‘.envrc’ file as safe.
