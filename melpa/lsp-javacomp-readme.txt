A lsp-mode client that provides Java code-completion and other IDE
features for Emacs. It's backed by JavaComp.

To use it, add the code below to your .emacs file:

   (require 'lsp-javacomp)
   (add-hook 'java-mode-hook #'lsp-javacomp-enable)
