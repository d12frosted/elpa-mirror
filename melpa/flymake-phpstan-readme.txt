Flymake backend for PHP using PHPStan (PHP Static Analysis Tool).

Put the following into your .emacs file (~/.emacs.d/init.el)

    (add-hook 'php-mode-hook #'flymake-phpstan-turn-on)

For Lisp maintainers: see [GNU Flymake manual - 2.2.2 An annotated example backend]
https://www.gnu.org/software/emacs/manual/html_node/flymake/An-annotated-example-backend.html
