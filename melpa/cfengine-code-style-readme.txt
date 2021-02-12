Usage:

To enable coding style for the current buffer:

    M-x c-set-style cfengine

To enable coding style permanently, create file .dir-locals.el with the
following contents in the directory with the source code:

    ((c-mode . ((c-file-style . "cfengine"))))



TODO: special rule for C99 (Foo) { 1, 2, 3 } initializers.
TODO: special rule for whitespace between if/while/for and paren.
