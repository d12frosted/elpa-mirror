This package is deprecated: Flycheck 38's built-in
`flycheck-annotate-mode' replaces it.  See the README for migration.

Provide an error display function to show Flycheck errors inline, directly
below their location in the buffer.

# Setup

Enable the local minor mode for all flycheck-mode buffers:

(with-eval-after-load 'flycheck
  (add-hook 'flycheck-mode-hook #'flycheck-inline-mode))
