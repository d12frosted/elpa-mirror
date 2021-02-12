Static analyze for PHP code using Psalm.
https://psalm.dev/

## Instalation

You need to get either the local PHP runtime or Docker and prepare for Psalm.
Please read the README for these details.
https://github.com/emacs-php/psalm.el/blob/master/README.org

If you are a Flycheck user, install `flycheck-psalm' package.

## Directory local variables

Put the following into .dir-locals.el files on the root directory of project.
Each variable can read what is documented by `M-x describe-variables'.

    ((nil . ((php-project-root . git)
             (psalm-executable . docker)
             (psalm-working-dir . (root . "path/to/dir"))
             (psalm-config-file . (root . "path/to/dir/psalm-docker.xml")))

If you want to know the directory variable specification, please refer to
M-x info [Emacs > Customization > Variables] or the following web page.
https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html
