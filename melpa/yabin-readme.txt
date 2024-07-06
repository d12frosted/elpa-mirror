Yabin is yet another big-number calculation package.
In fact, this is only a wrapper of `calc', but it's a little bit useful
than using directly.

Difference of math-*/calcFunc-* functions:

 * Parameters are automatically normalized.  Floating, string number
   and also `calc' package's internal form can be used directly.
 * A result is automatically formatted to string number.
 * Some operation's behavior is changed as same as Emacs native one,
   such as `yabin-div' and `yabin-reminder.'
 * Infinite and NaN automatically converted Emacs native representation.
 * Only support integer and floating number.  Complex numbers are converted
   into NaN.  For vectors, operation isn't defined.  Fractions are supported
   only as input parameter.
