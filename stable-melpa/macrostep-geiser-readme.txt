Provides `macrostep' support for `geiser' and `cider'.

To enable `macrostep' in `geiser-mode' buffer, execute
`macrostep-geiser-setup'. The latter function can be added to
`geiser-mode-hook' and `geiser-repl-mode-hook':

(eval-after-load 'geiser-mode '(add-hook 'geiser-mode-hook #'macrostep-geiser-setup))
(eval-after-load 'geiser-repl '(add-hook 'geiser-repl-mode-hook #'macrostep-geiser-setup))

Or, using `use-package':

(use-package macrostep-geiser
  :after geiser-mode
  :config (add-hook 'geiser-mode-hook #'macrostep-geiser-setup))

(use-package macrostep-geiser
  :after geiser-repl
  :config (add-hook 'geiser-repl-mode-hook #'macrostep-geiser-setup))

Additionally, for `cider' integration:

(eval-after-load 'cider-mode '(add-hook 'cider-mode-hook #'macrostep-geiser-setup))

Or, using `use-package':

(use-package macrostep-geiser
  :after cider-mode
  :config (add-hook 'cider-mode-hook #'macrostep-geiser-setup))
