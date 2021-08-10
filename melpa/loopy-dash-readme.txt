
This package is an optional extension for the package `loopy'.

The `loopy' macro is used to generate code for a loop, similar to `cl-loop'.
Unlike `cl-loop', `loopy' uses symbolic expressions instead of "clauses".

This package provides a way to use the destructuring features of the Dash
library in `loopy'.

    ;; => ((1 4)            coll1
    ;;     ((2 3) (5 6))    whole
    ;;     (2 5)            x
    ;;     (3 6))           y
    (require 'loopy-dash)
    (loopy (flag dash)
           (list (i j) '((1 (2 3)) (4 (5 6))))
           (collect coll1 i)
           (collect (whole &as x y) j)
           (finally-return coll1 whole x y))

For more information, including the full list of loop commands and how to
extend the macro, see the main package's comprehensive Info documentation
under the Info node `(loopy)'.
