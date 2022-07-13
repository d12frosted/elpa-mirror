Auto virtualenv activates virtualenv automatically when called.
To use auto-virtualenv set hooks for `auto-virtualenv-set-virtualenv'
To set a custom virtualenv path set variable `auto-virtualenv-custom-virtualenv-path'

For example:
(require 'auto-virtualenv)
(add-hook 'python-mode-hook 'auto-virtualenv-set-virtualenv)
(add-hook 'projectile-after-switch-project-hook 'auto-virtualenv-set-virtualenv)
