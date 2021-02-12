Static analyze for PHP code using PHPStan.
https://github.com/phpstan/phpstan

## Instalation

You need to get either the local PHP runtime or Docker and prepare for PHPStan.
Please read the README for these details.
https://github.com/emacs-php/phpstan.el/blob/master/README.org

If you are a Flycheck user, install `flycheck-phpstan' package.

## Directory local variables

Put the following into .dir-locals.el files on the root directory of project.
Each variable can read what is documented by `M-x describe-variables'.

    ((nil . ((php-project-root . git)
             (phpstan-executable . docker)
             (phpstan-working-dir . (root . "path/to/dir"))
             (phpstan-config-file . (root . "path/to/dir/phpstan-docker.neon"))
             (phpstan-level . 7))))

If you want to know the directory variable specification, please refer to
M-x info [Emacs > Customization > Variables] or the following web page.
https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html
