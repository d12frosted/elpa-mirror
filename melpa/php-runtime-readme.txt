Execute PHP code.  This package requires `php' command in runtime.

    (string-to-number (php-runtime-eval "echo PHP_INT_MAX;"))
    ;; => 9.223372036854776e+18

    (string-to-number (php-runtime-expr "PHP_INT_MAX")) ; short hand
