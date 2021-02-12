This file provides a flymake-based spell-checker for documents
using GNU Aspell as a backend.  Enable it by adding the following
to your init file.  You must be running Emacs 26 or newer in order
to use the new version of Flymake.

  (add-hook 'text-mode-hook #'flymake-aspell-setup)
