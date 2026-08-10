This package is deprecated: Flycheck 38's built-in
`flycheck-annotate-mode' replaces it, in GUI and terminal frames
alike.  See the README for migration.

Provide an error display function to show errors in a tooltip.

;; Setup

(with-eval-after-load 'flycheck
  (flycheck-pos-tip-mode))
