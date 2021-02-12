Adds a few keyboard shortcuts to `php-mode' (e.g. C-c C-c) to send
code from a PHP buffer to the Boris PHP repl and evaluate it there.

To enable, enable `php-boris-minor-mode' in `php-mode':

    (add-hook 'php-mode-hook 'php-boris-minor-mode)
