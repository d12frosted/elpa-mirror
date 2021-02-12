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
