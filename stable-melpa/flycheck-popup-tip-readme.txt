This package is deprecated: Flycheck 38's built-in
`flycheck-annotate-mode' replaces it, in GUI and terminal frames
alike.  See the README for migration.

This is extension for Flycheck.

It displays Flycheck error messages in buffer using `popup.el' library.

For more information about Flycheck:
http://www.flycheck.org/
https://github.com/flycheck/flycheck

For more information about this Flycheck extension:
https://github.com/flycheck/flycheck-popup-tip

;; Setup

Add to your `init.el':

(with-eval-after-load 'flycheck
  '(add-hook 'flycheck-mode-hook 'flycheck-popup-tip-mode))
