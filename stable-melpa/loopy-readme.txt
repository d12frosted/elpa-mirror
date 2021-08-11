The `loopy' macro is used to generate code for a loop, similar to `cl-loop'.
Unlike `cl-loop', `loopy' uses symbolic expressions instead of "clauses".

A simple usage of `cl-loop':

    (cl-loop for i from 1 to 10
             if (cl-evenp i) collect i into evens
             else collect i into odds
             end ; This `end' keyword is optional here.
             finally return (list odds evens))

How it could be done using `loopy':

    (loopy (numbers i 1 10)
           (if (cl-evenp i)
               (collect evens i)
             (collect odds i))
           (finally-return odds evens))

`loopy' supports destructuring for iteration commands like `list' and
accumulation commands like `sum' or `collect'.

    ;; Summing the nth elements of arrays:
    ;; => (8 10 12 14 16 18)
    (loopy (list (list-elem1 list-elem2)
                 '(([1 2 3] [4 5 6])
                   ([7 8 9] [10 11 12])))
           (sum [sum1 sum2 sum3] list-elem1)
           (sum [sum4 sum5 sum6] list-elem2)
           (finally-return sum1 sum2 sum3 sum4 sum5 sum6))

    ;; Or, more simply:
    ;; => (8 10 12 14 16 18)
    (loopy (list list-elem '(([1 2 3] [4 5 6])
                             ([7 8 9] [10 11 12])))
           (sum ([sum1 sum2 sum3] [sum4 sum5 sum6])
                list-elem)
           (finally-return sum1 sum2 sum3 sum4 sum5 sum6))

    ;; Separate the elements of sub-list:
    ;; => ((1 3) (2 4))
    (loopy (list i '((1 2) (3 4)))
           (collect (elem1 elem2) i)
           (finally-return elem1 elem2))

The `loopy' macro is configurable and extensible.  In addition to writing
one's own "loop commands" (such as `list' in the example below), by using
"flags", one can choose whether to instead use `pcase-let', `seq-let', or
even the Dash library for destructuring.

    ;; Use `pcase' to destructure array elements:
    ;; => ((1 2 3 4) (10 12 14) (11 13 15))
    (loopy (flag pcase)
           (array (or `(,car . ,cdr) digit)
                  [1 (10 . 11) 2 (12 . 13) 3 4 (14 . 15)])
           (if digit
               (collect digits digit)
             (collect cars car)
             (collect cdrs cdr))
           (finally-return digits cars cdrs))

    ;; Using the default destructuring:
    ;; => ((1 2 3 4) (10 12 14) (11 13 15))
    (loopy (array elem [1 (10 . 11) 2 (12 . 13) 3 4 (14 . 15)])
           (if (numberp elem)
               (collect digits elem)
             (collect (cars . cdrs) elem))
           (finally-return digits cars cdrs))

Variables like `cars', `cdrs', and `digits' in the example above are
automatically `let'-bound so as to not affect code outside of the loop.

`loopy' has arguments for binding (or not binding) variables, executing code
before/after the loop, executing code only if the loop completes, and for
setting the macro's return value (default `nil').  This is in addition to the
looping features themselves.

All of this makes `loopy' a useful and convenient choice for looping and
iteration.

That being said, Loopy is not yet feature complete.  Please request features
or report problems in this project’s issues tracker
(<https://github.com/okamsn/loopy/issues>).  While most cases are covered,
full feature parity with some of the more niche uses of `cl-loop' is still
being worked on.

For more information, including the full list of loop commands and how to
extend the macro, see this package's comprehensive Info documentation under
the Info node `(loopy)'.
