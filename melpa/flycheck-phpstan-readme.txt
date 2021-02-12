Flycheck integration for PHPStan.

Put the following into your .emacs file (~/.emacs.d/init.el)

    (defun my-php-mode-setup ()
      "My PHP-mode hook."
      (require 'flycheck-phpstan)
      (flycheck-mode t))

    (add-hook 'php-mode-hook 'my-php-mode-setup)
