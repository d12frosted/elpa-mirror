Flycheck integration for PHPStan.

Put the following into your .emacs file (~/.emacs.d/init.el)

    (defun my-php-mode-setup ()
      "My PHP-mode hook."
      (require 'flycheck-phpstan)
      (flycheck-mode t))

    (add-hook 'php-mode-hook 'my-php-mode-setup)

## For Lisp maintainers

This is a generic checker (`flycheck-define-generic-checker'), not a command
checker (`flycheck-define-checker').  A command checker takes its executable
from the car of `:command', which must be a literal string, overridable only
through the single string variable `flycheck-CHECKER-executable'.  PHPStan
does not fit that shape: `phpstan-executable' may expand to a whole command
line such as `docker run --rm -v ...', and it is chosen per project.  So we
drive the process ourselves and build the command from `phpstan-executable'.
