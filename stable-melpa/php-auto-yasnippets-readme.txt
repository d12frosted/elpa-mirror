
This package provides a function that automatically creates
snippets for PHP standard library functions, for use with the
YASnippets package, available at:

https://github.com/capitaomorte/yasnippet

This package also requires php-mode, available at:

https://github.com/ejmr/php-mode

To use php-auto-yasnippets you need to do three things.  First,
place the package in your load-path (`C-h v load-path' for help)
and load it from your Emacs configuration file by adding:

(require 'php-auto-yasnippets)

Second, make sure the variable `php-auto-yasnippet-php-program'
points to the program `Create-PHP-YASnippet.php'.  That PHP program
should have come with this package; if you do not have it then you
can get it from the project GitHub URL at the top of this file.  By
default this package looks for the PHP program in the same
directory as this Elisp file.  You can use `setq' in your
configuration file to set the variable to the proper path if the
PHP program is in a different directory, e.g:

(require 'php-auto-yasnippets)
(setq php-auto-yasnippet-php-program "~/path/to/Create-PHP-YASnippet.php")

Finally, bind the function `yas/create-php-snippet' to a key of
your choice.  Since this package requires php-mode, and since it is
most useful when writing PHP code, you may want to use a
key-binding that only works when using php-mode.  For example:

(define-key php-mode-map (kbd "C-c C-y") 'yas/create-php-snippet)

Now if you type the name of a PHP function and press `C-c C-y' it
will expand into a snippet containing all of the parameters, their
names, any default values, et cetera.  If you type the name of a
method then you need to tell the package the name of the class that
implements that method, otherwise it will not be able to create the
snippet.  Using the prefix command, e.g. `C-u C-c C-y', prompts for
the class name in the minibuffer.
