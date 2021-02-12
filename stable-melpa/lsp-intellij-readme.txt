lsp-mode client for intellij-lsp-server.
After installing lsp-mode, you can use it as follows:

(with-eval-after-load 'lsp-mode
  (require 'lsp-intellij)
  (add-hook 'java-mode-hook #'lsp-intellij-enable))

Then, after opening and configuring a project in your instance of
IntelliJ that has intellij-lsp-server, navigate to a Java file tracked
by that project.
