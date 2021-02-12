This package adds support for Pyre type checker to flycheck.
To use it, add to your init.el:

(require 'flycheck)
(require 'flycheck-pyre)
(eval-after-load 'flycheck
  '(add-hook 'flycheck-mode-hook #'flycheck-pyre-setup))
(defun my/configure-python-mode-flycheck-checkers ()
  ;; configure all your checkers for python-mode here
  (flycheck-mode)
  (flycheck-select-checker 'python-pyre)
  )
(add-hook 'python-mode-hook #'my/configure-python-mode-flycheck-checkers)
