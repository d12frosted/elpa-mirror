This package simply provides conversion to English ordinal numbers.
(ex.  1st, 2nd, 3rd, 4th... Nth)

It is worth noting that this function accepts "0th" for compatibility with function `nth'.
If you do not like it you can control it with the ordinal-number-accept-0 variable.

(ordinal-format 0) ;; => "0th"

You can prohibit "0th" for correct English.

(let ((ordinal-number-accept-0 nil))
  (ordinal-format 0))
;; =>  Assertion failed: (>= n 1)

This variable works with dynamic scope.  Do not use `setq' for `ordinal-number-accept-0'.
