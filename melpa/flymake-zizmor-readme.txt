This package provides flymake backend for zizmor, a Github Actions
static analyzer.  To use it, add the following to your init file:

  (add-hook 'yaml-ts-mode-hook #'flymake-zizmor-setup)

See https://zizmor.sh/ for how to install zizmor.

As an alternative, there is also a lsp mode in the works:
https://github.com/zizmorcore/zizmor/issues/516
