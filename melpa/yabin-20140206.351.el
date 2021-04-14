;;; yabin.el --- Yet Another Bignum package (A thin wrapper of calc.el).

;; Copyright (C) 2013, 2014  Daisuke Kobayashi

;; Author: Daisuke Kobayashi <d5884jp@gmail.com>
;; Keywords: data
;; Package-Version: 20140206.351
;; Package-Commit: db8c404507560ef9147fcce2b94cd706fbfa03b5
;; Version: 1.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Yabin is yet another big-number calculation package.
;; In fact, this is only a wrapper of `calc', but it's a little bit useful
;; than using directly.

;; Difference of math-*/calcFunc-* functions:

;;  * Parameters are automatically normalized.  Floating, string number
;;    and also `calc' package's internal form can be used directly.
;;  * A result is automatically formatted to string number.
;;  * Some operation's behavior is changed as same as Emacs native one,
;;    such as `yabin-div' and `yabin-reminder.'
;;  * Infinite and NaN automatically converted Emacs native representation.
;;  * Only support integer and floating number.  Complex numbers are converted
;;    into NaN.  For vectors, operation isn't defined.  Fractions are supported
;;    only as input parameter.

;;; Installed functions:

;;  All public functions have alias name that prefix replaced like
;;  `yabin-OPERATION' -> `!OPERATION', and some functions that exists
;;  equivalent operation on native have more short alias name.

;;  Public functions list is below (prefix `yabin-' is omitted.)

;;  * Basic arithmetic
;;    add (!+), add1 (!1+), sub (yabin-minus, !-), sub1 (!1-), -multi (!*),
;;    div (!/), reminder (!%), mod, expt (power, !^), abs, max, min

;;  * Application function
;;    sin, cos, tan, asin, acos, atan, log, log10, exp, sqrt, nth-root,
;;    fact, gcd, lcm

;;  * Random
;;    random, shuffle

;;  * Conversion
;;    ceiling, floor, round, truncate, float, ffloor, fceiling, fround, radix

;;  * Bitwise operation
;;    ash, rash, lsh, rsh, rot, logand, logior, logxor, logdiff, lognot

;;  * Binary oriented conversion
;;    limit-nbit, limit-nbyte, overflowp, clip, unsigned, signed, pack,
;;    number-to-unibyte-string, unpack (unibyte-string-to-number)

;;  * Predicate
;;    numberp, natnump, integerp, oddp, evenp, posp, negp, zerop, floatp,
;;    isnan, isinf

;;  * Comparator
;;    equal (!=), not-equal (!/=), less-than (!<), less-than-equal (!<=),
;;    greater-than (!>), greater-than-equal (!>=)

;;  * Formatting
;;    format, format-spec

;;; Code:

(eval-and-compile
  (require 'calc)
  (require 'calc-ext))

(defconst yabin-emacs-integer-bit-width ;; log(POSMAX+1,2)+1
  (math-add
   (calcFunc-log (math-add (math-bignum most-positive-fixnum) 1) 2) 1)
  "The bit width of integer value that can handled by Emacs.
This value is calculated from `most-positive-fixnum'.")

(defvar yabin-internal-prec 20
  "Internal precision for calculating floating number.")

(defvar yabin-exponential-form-threshold '(6 . -5)
  "If float number's exponent is over this range, it's displayed exponential form.")

;;
;; internal functions and macros
;;


(eval-and-compile
  (defconst yabin--math-pnan (eval-when-compile
			       (let ((calc-infinite-mode t)) (math-div 0 0)))
    "The positive NaN value of `calc' package.")
  (defconst yabin--math-nnan (eval-when-compile
			       (let ((calc-infinite-mode t)) (list 'neg (math-div 0 0))))
    "The negative NaN value of `calc' package.")
  (defconst yabin--math-pinf (eval-when-compile
			       (let ((calc-infinite-mode 1)) (math-div 1 0)))
    "The positive infinite value of `calc' package.")
  (defconst yabin--math-ninf (eval-when-compile
			       (let ((calc-infinite-mode -1)) (math-div 1 0)))
    "The negative infinite value of `calc' package.")
  (defconst yabin--math-uinf (eval-when-compile
			       (let ((calc-infinite-mode t)) (math-div 1 0)))
    "The undirective infinite value of `calc' package.")

  (defconst yabin--nan-alist
    (eval-when-compile
      `((,(number-to-string  0.0e+NaN) . ,yabin--math-pnan)
	(,(number-to-string -0.0e+NaN) . ,yabin--math-nnan)
	(,(number-to-string  1.0e+INF) . ,yabin--math-pinf)
	(,(number-to-string -1.0e+INF) . ,yabin--math-ninf)
	(,(number-to-string  1.0e+INF) . ,yabin--math-uinf)))
    "Alist of Emacs's NaN and infinite representation and `calc' package's one.")

  (defconst yabin--default-calc-setting-alist
    '((calc-display-working-message nil)
      (calc-timing nil)

      (calc-internal-prec yabin-internal-prec)
      (calc-float-format '(float 0))
      (calc-full-float-format '(float 0))
      (calc-display-sci-high (car yabin-exponential-form-threshold))
      (calc-display-sci-low (cdr yabin-exponential-form-threshold))

      (calc-infinite-mode nil)
      (calc-simplify-mode 'alg)

      (calc-radix-formatter nil)
      (calc-number-radix 10)
      (calc-leading-zeros nil)
      (calc-group-digits nil)

      (calc-frac-format '(":" nil))
      (calc-prefer-frac nil)

      (calc-language nil)
      (calc-word-size 32)

      (calc-display-raw nil)
      (calc-symbolic-mode nil))
    "Default `calc' environment values.")

  (defconst yabin--default-format-precision 6
    "Default precision value using format.")
  )

(defun yabin--read-number (string)
  "Convert STRING into `calc' package's internal form."
  (or (cdr (assoc string yabin--nan-alist))
      (math-read-number string)))

(defun yabin--normalize (value)
  "Convert VALUE into `calc' package's internal form.
VALUE can take integer, float, string and `calc' package's internal form ."
  (let ((number (cond
		 ((integerp value)
		  (math-normalize value))
		 ((floatp value)
		  (yabin--read-number (prin1-to-string value t)))
		 ((stringp value)
		  (yabin--read-number value))
		 ((consp value)
		  value)
		 (t nil))))

    (if (or (math-realp number)
	    (math-infinitep number))
	number
      (signal 'wrong-type-argument (list 'yabin-numberp value)))))

(defun yabin--to-string (value)
  "Convert `calc' package's internal form VALUE into string."
  (cond
   ((math-infinitep value)
    (car (rassoc value yabin--nan-alist)))
   ((not (math-realp value))		     ; complex, vector
    (car (rassoc value yabin--math-pnan)))   ;    => nan
   ((not (math-integerp value))		     ; fraction (and float)
    (math-format-number (math-float value))) ;    => float
   (t
    (math-format-number value))))

(defun yabin--r-reduce (op init numbers)
  "Reduce two-argument OP across INIT and NUMBERS reversibly.
INIT and NUMBERS are converted by `yabin--normalize'."
  (cond
   ((null numbers)
    init)
   (t
    (funcall op
	     (yabin--r-reduce op init (cdr numbers))
	     (yabin--normalize (car numbers))
	     ))))

(eval-when-compile
  (defmacro yabin--local-env (override-alist &rest body)
    "Eval BODY with local `calc' package's environment.
Environment variables set by `yabin--default-calc-setting-alist'.
If OVERRIDE-ALIST is non-nil, local variable set by."
    `(let* ,(append
	     (delq nil
		   (mapcar (lambda (pair)
			     (unless (assoc (car pair)
					    override-alist)
			       pair))
			   yabin--default-calc-setting-alist))
	     override-alist)
       ,@body
       ))

  (defmacro yabin--funcall (func num &rest nums)
    "Call FUNC with argument NUM and NUMS.
Arguments are converted by `yabin--nomalize',
and return value is converted by `yabin--to-string'."
    `(yabin--to-string
      ,(cons 'funcall (cons func
			    (mapcar (lambda (n)
				      (list 'yabin--normalize n))
				    (cons num nums))))))

  (defmacro yabin--funcall-no-format (func num &rest nums)
    "Call FUNC with argument NUM and NUMS.
Arguments are converted by `yabin--nomalize'."
    (cons 'funcall (cons func
			 (mapcar (lambda (n)
				   (list 'yabin--normalize n))
				 (cons num nums)))))

  (defmacro yabin--funcall-logical (func bit-width unsigned-p num &rest nums)
    "Call FUNC with argument NUM, NUMS and bit width parameter.
A bit width parameter is calculated by BIT-WIDTH and UNSIGNED-P.
If BIT-WIDTH is nil, it takes `yabin-emacs-integer-bit-width'.
If UNSIGNED-P is non-nil, NUM and NUMS are handled as unsigned integer.
Arguments are converted by `yabin--nomalize'.
and return value is converted by `yabin--to-string'."
    `(yabin--to-string
      ,(cons 'funcall
	     (cons func
		   (nconc (mapcar (lambda (n)
				     (list 'yabin--normalize n))
				   (cons num nums))
			   (list `(let ((bit-width (yabin--normalize
						    (or ,bit-width
							yabin-emacs-integer-bit-width))))
				    (if ,unsigned-p bit-width (math-neg bit-width)))))))))

  (defmacro yabin--predicate (value &rest preds)
    "Call predicate functions for VALUE.
Return t if one of PRED and PREDS is satisfied."
    `(let ((num (condition-case nil
		    (yabin--normalize ,value)
		  (wrong-type-argument nil))))
       (when
	   ,(if (null preds)
		'num
	      `(and num
		    (or ,@(mapcar (lambda (p) (list 'funcall p 'num))
				  preds))))
	 t)))


  (defmacro yabin--signal-division-by-zero ()
    "Signal \"division by zero\" error."
    '(signal 'arith-error "Division by zero"))

  )
;;
;; public functions
;;

;; basic arithmetics

(defun yabin-add (&rest numbers)
  "Return sum of any NUMBERS of arguments."
  (yabin--local-env
   nil
   (yabin--to-string (yabin--r-reduce 'math-add 0 numbers))))

(defsubst yabin-add1 (number)
  "Return NUMBER plus one."
  (yabin-add number 1))

(defun yabin-sub (&optional number &rest numbers)
  "Negate NUMBER or subtract NUMBERS and return the result.
With one arg, negates it.  With more than one arg,
subtracts all but the first from the first."
  (yabin--local-env
   nil
   (yabin--to-string
    (cond
     ((null number)
      0)
     ((null numbers)
      (math-neg (yabin--normalize number)))
     (t
      (math-sub (yabin--normalize number)
		(yabin--r-reduce 'math-add 0 numbers)))))))

(defalias 'yabin-minus 'yabin-sub)

(defsubst yabin-sub1 (number)
  "Return NUMBER minus one."
  (yabin-sub number 1))

(defun yabin-multi (&rest numbers)
  "Return product of any NUMBERS of arguments."
  (yabin--local-env
   nil
   (yabin--to-string (yabin--r-reduce 'math-mul 1 numbers))))

(defun yabin-div (dividend divisor &rest divisors)
  "Return DIVIDEND divided by all the remaining DIVISOR and DIVISORS.
If all arguments are integer, a return value is truncated to integer."
  (yabin--local-env
   ((dividend (yabin--normalize dividend))
    (divisor (yabin--r-reduce 'math-mul 1 (cons divisor divisors)))
    (calc-infinite-mode (or (math-floatp dividend)
			    (math-floatp divisor))))
   (when (and (math-zerop divisor)
	      (not calc-infinite-mode))
     (yabin--signal-division-by-zero))
   (yabin--to-string (if calc-infinite-mode
			 (math-div dividend divisor)
		       (math-trunc (math-div dividend divisor))))))

(defun yabin-reminder (x y)
  "Return remainder of X divided by Y."
  (yabin--local-env
   ((x (yabin--normalize x))
    (y (math-abs (yabin--normalize y)))
    mod)
   (if (math-zerop y)
       (yabin--signal-division-by-zero))
   (setq mod (math-mod (math-abs x) y))
   (yabin--to-string
    (if (math-negp x) (math-neg mod) mod))))

(defun yabin-mod (x y)
  "Return X modulo Y.
The result falls between zero (inclusive) and Y (exclusive)."
  (yabin--local-env
   ((x (yabin--normalize x))
    (y (yabin--normalize y)))
   (when (math-zerop y)
     (yabin--signal-division-by-zero))
   (yabin--to-string (math-mod x y))))

(defun yabin-expt (x y)
  "Return the exponential X ** Y."
  (yabin--local-env nil (yabin--funcall 'math-pow x y)))

(defalias 'yabin-power 'yabin-expt)

(defun yabin-abs (number)
  "Return the absolute value of NUMBER."
  (yabin--local-env nil (yabin--funcall 'math-abs number)))

(defun yabin-max (number &rest numbers)
  "Return largest of all the arguments NUMBER and NUMBERS."
  (yabin--local-env nil (yabin--r-reduce 'math-max number numbers)))

(defun yabin-min (number &rest numbers)
  "Return smallest of all the arguments NUMBER and NUMBERS."
  (yabin--local-env nil (yabin--r-reduce 'math-min number numbers)))

;; application functions

(defun yabin-sin (number)
  "Return the sine of NUMBER."
  (yabin--local-env nil (yabin--funcall 'calcFunc-sin number)))

(defun yabin-cos (number)
  "Return the cosine of NUMBER."
  (yabin--local-env nil (yabin--funcall 'calcFunc-cos number)))

(defun yabin-tan (number)
  "Return the tangent of NUMBER."
  (yabin--local-env nil (yabin--funcall 'calcFunc-tan number)))

(defun yabin-asin (number)
  "Return the inverse sine of NUMBER."
  (yabin--local-env nil (yabin--funcall 'calcFunc-arcsin number)))

(defun yabin-acos (number)
  "Return the inverse cosine of NUMBER."
  (yabin--local-env nil (yabin--funcall 'calcFunc-arccos number)))

(defun yabin-atan (y &optional x)
  "Return the inverse tangent of the arguments.
If only one argument Y is given, return the inverse tangent of Y.
If two arguments Y and X are given, return the inverse tangent of Y
divided by X, i.e. the angle in radians between the vector (X, Y)
and the x-axis."
  (yabin--local-env
   nil
   (if x
       (yabin--funcall 'calcFunc-arctan2 y x)
     (yabin--funcall 'calcFunc-arctan y))))

(defun yabin-log (number &optional base)
  "Return the natural logarithm of NUMBER.
If the optional argument BASE is given, return log NUMBER using that base."
  (yabin--local-env
   nil
   (if base
       (yabin--funcall 'calcFunc-log number base)
     (yabin--funcall 'calcFunc-log number))))

(defun yabin-log10 (number)
  "Return the logarithm base 10 of NUMBER."
  (yabin--local-env nil (yabin--funcall 'calcFunc-log10 number)))

(defun yabin-exp (number)
  "Return the exponential base e of NUMBER."
  (yabin--local-env nil (yabin--funcall 'calcFunc-exp number)))

(defun yabin-sqrt (number)
  "Return the square root of NUMBER."
  (yabin--local-env nil (yabin--funcall 'math-sqrt number)))

(defun yabin-nth-root (number n)
  "Return the N-th root of NUMBER."
  (yabin--local-env nil (yabin--funcall 'math-nth-root number n)))

(defun yabin-fact (number)
  "Return factorial number of NUMBER."
  (yabin--local-env nil (yabin--funcall 'calcFunc-fact number)))

(defun yabin-gcd (int1 int2)
  "Return gcd value of INT1 and INT2."
  (yabin--local-env nil (yabin--funcall 'math-gcd int1 int2)))

(defun yabin-lcm (int1 int2)
  "Return lcm value of INT1 and INT2."
  (yabin-div (yabin-multi int1 int2) (yabin-gcd int1 int2)))

;; randoms

(defun yabin-random (max)
  "Return random number between 0 and MAX - 1."
  (yabin--funcall 'calcFunc-random max))

(defun yabin-shuffle (n &optional max)
  "Return a list of non-duplicated N random numbers between 0 and MAX - 1.
N must be less than or equal MAX.
If MAX is nil, random number is generated between 0 and N - 1."
  (yabin--local-env
   nil
   (mapcar 'yabin--to-string
	   (cdr (if max
		    (yabin--funcall-no-format 'calcFunc-shuffle n max)
		  (yabin--funcall-no-format 'calcFunc-shuffle n))))))

;; conversions

(defun yabin-ceiling (number)
  "Return the smallest integer no less than NUMBER.
This rounds the value towards +inf."
  (yabin--local-env nil (yabin--funcall 'math-ceiling number)))

(defun yabin-floor (number)
  "Return the largest integer no greater than NUMBER.
This rounds the value towards -inf."
  (yabin--local-env nil (yabin--funcall 'math-floor number)))

(defun yabin-round (number)
  "Return the nearest integer to NUMBER.
Rounding a value equidistant between two integers may choose the
integer closer to zero."
  (yabin--local-env nil (yabin--funcall 'math-round number)))

(defun yabin-truncate (number)
  "Truncate a floating point number to an int.
Rounds NUMBER toward zero."
  (yabin--local-env nil (yabin--funcall 'math-trunc number)))

(defun yabin-float (number)
  "Return the floating point number equal to NUMBER."
  (yabin--local-env nil (yabin--funcall 'math-float number)))

(defun yabin-ffloor (number)
  "Return the largest integer no greater than NUMBER, as a float.
\(Round towards -inf.\)"
  (yabin--local-env nil (yabin--funcall 'calcFunc-ffloor number)))

(defun yabin-fceiling (number)
  "Return the smallest integer no less than NUMBER, as a float.
\(Round toward +inf.\)"
  (yabin--local-env nil (yabin--funcall 'calcFunc-fceil number)))

(defun yabin-ftruncate (number)
  "Truncate a floating point NUMBER to an integral float value.
Rounds the value toward zero."
  (yabin--local-env nil (yabin--funcall 'calcFunc-ftrunc number)))

(defun yabin-fround (number)
  "Return the nearest integer to NUMBER, as a float."
  (yabin--local-env nil (yabin--funcall 'calcFunc-fround number)))

(defun yabin-radix (number radix &optional bit-width omit-prefix)
  "Convert NUMBER's radix to RADIX.
If BIT-WIDTH is specified, `0' is filled up to the head by BIT-WIDTH
integer length.
If OMIT-PREFIX is non-nil, `calc' package's radix prefix (ex: \"16#\") is
omitted.

A radix converted number can be used for other yabin function's parameter,
 without prefix omitted case."
  (yabin--local-env
   ((calc-number-radix radix)
    (math-radix-explicit-format (not omit-prefix))
    (calc-radix-formatter (when omit-prefix
			    (lambda (rad num) (format "%s" num))))
    (calc-word-size (or bit-width calc-word-size))
    (calc-leading-zeros bit-width))
   (yabin--to-string (yabin--normalize number))))

;; bitwise operations

(defun yabin-ash (integer count &optional bit-width unsigned-p)
  "Return INTEGER with its bits shifted left by COUNT.
If COUNT is negative, shifting is actually to the right.
In this case, the sign bit is duplicated.
If BIT-WIDTH is nil, INTEGER is considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, INTEGER is converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-ash bit-width unsigned-p integer count)))

(defun yabin-rash (integer count &optional bit-width unsigned-p)
  "Return INTEGER with its bits shifted right by COUNT.
In this case, the sign bit is duplicated.
If COUNT is negative, shifting is actually to the left.
If BIT-WIDTH is nil, INTEGER is considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, INTEGER is converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-rash bit-width unsigned-p integer count)))

(defun yabin-lsh (integer count &optional bit-width unsigned-p)
  "Return INTEGER with its bits shifted left by COUNT.
If COUNT is negative, shifting is actually to the right.
In this case, zeros are shifted in on the left.
If BIT-WIDTH is nil, INTEGER is considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, INTEGER is converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-lsh bit-width unsigned-p integer count)))

(defun yabin-rsh (integer count &optional bit-width unsigned-p)
  "Return INTEGER with its bits shifted right by COUNT.
In this case, zeros are shifted in on the left.
If COUNT is negative, shifting is actually to the left.
If BIT-WIDTH is nil, INTEGER is considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, INTEGER is converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-rsh bit-width unsigned-p integer count)))

(defun yabin-rot (integer count &optional bit-width unsigned-p)
  "Return INTEGER with its bits rotated left by COUNT.
If COUNT is negative, rotating is actually to the left.
If BIT-WIDTH is nil, INTEGER is considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, INTEGER is converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-rot bit-width unsigned-p integer count)))

(defun yabin-logand (int1 int2 &optional bit-width unsigned-p)
  "Return bitwise-and of INT1 and INT2.
If BIT-WIDTH is nil, arguments are considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, arguments are converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-and bit-width unsigned-p int1 int2)))

(defun yabin-logior (int1 int2 &optional bit-width unsigned-p)
  "Return bitwise-or of INT1 and INT2.
If BIT-WIDTH is nil, arguments are considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, arguments are converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-or bit-width unsigned-p int1 int2)))

(defun yabin-logxor (int1 int2 &optional bit-width unsigned-p)
  "Return bitwise-xor of INT1 and INT2.
If BIT-WIDTH is nil, arguments are considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, arguments are converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-xor bit-width unsigned-p int1 int2)))

(defun yabin-logdiff (int1 int2 &optional bit-width unsigned-p)
  "Return bitwise-diff of INT1 and INT2.
If BIT-WIDTH is nil, arguments are considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, arguments are converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-diff bit-width unsigned-p int1 int2)))

(defun yabin-lognot (integer &optional bit-width unsigned-p)
  "Return bitwise-not of INTEGER.
If BIT-WIDTH is nil, INTEGER is considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, INTEGER is converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'calcFunc-not bit-width unsigned-p integer)))

;; binary oriented

(defun yabin-limit-nbit (bit-width &optional unsigned-p) ; (pos . neg)
  "Return upper and lower limit of the integer had BIT-WIDTH.
Return value formed (upper . lower), car is upper limit,
and cdr is lower limit.
If UNSIGNED-P is non-nil, limits are calculated for unsigned integer."
  (if unsigned-p
      (cons (yabin-sub1 (yabin-expt 2 bit-width)) "0")
    (let ((bit-width (yabin-sub1 bit-width)))
      (cons (yabin-sub1 (yabin-expt 2 bit-width))
	    (yabin-expt -2 bit-width)))))

(defun yabin-limit-nbyte (byte-width &optional unsigned-p)
  "Return upper and lower limit of the integer had BYTE-WIDTH.
Return value formed (upper . lower), car is upper limit,
and cdr is lower limit.
If UNSIGNED-P is non-nil, limits are calculated for unsigned integer."
  (yabin-limit-nbit (yabin-multi byte-width 8) unsigned-p))

(defun yabin-overflowp (number &optional bit-width unsigned-p)
  "Return non-nil if NUMBER is overflowed or underflowed.
If BIT-WIDTH is nil, INTEGER is considered as Emacs native integer,
otherwise integer had BIT-WIDTH length.
If UNSIGNED-P is non-nil, unsigned integer limitation is used."
  (let ((limits (cond
		 (bit-width (yabin-limit-nbit bit-width unsigned-p))
		 (unsigned-p  (cons most-positive-fixnum "0"))
		 (t         (cons most-positive-fixnum most-negative-fixnum)))))
    (or (yabin-greater-than-equal number (cdr limits))
	(yabin-less-than-equal number (car limits)))))

(defun yabin-clip (integer &optional bit-width unsigned-p)
  "Return INTEGER cliped by BIT-WIDTH size.
If UNSIGNED-P is non-nil, INTEGER is converted into unsigned integer
before operation."
  (yabin--local-env
   nil
   (yabin--funcall-logical 'math-clip bit-width unsigned-p integer)))

(defsubst yabin-unsigned (integer bit-width)
  "Return INTEGER cliped as BIT-WIDTH unsigned integer."
  (yabin-clip integer bit-width t))

(defsubst yabin-signed (integer bit-width)
  "Return INTEGER cliped as BIT-WIDTH signed integer."
  (yabin-clip integer bit-width))

(defun yabin-pack (integer byte-width &optional byte-order)
  "Convert INTEGER into byte vector.
BYTE-WIDTH specifies INTEGER's byte-width.
The result vector's order is decided by BYTE-ORDER parameter:

66  (?B - ascii uppercase B) - big endian.  Ordered from higher to lower.
108 (?l - ascii lowercase l) - little endian.  Ordered from lower to higher.
If BYTE-ORDER is nil, system value (result of `byteorder') is used."
  (yabin--local-env
   nil
   (let ((bytes-le (yabin--get-bytes-le (yabin--normalize integer) byte-width)))
     (apply 'vector (if (eq ?B (or byte-order (byteorder)))
			(reverse bytes-le)
		      bytes-le)))))

(defun yabin--get-bytes-le (normalized byte-width)
  "Convert NORMALIZED into byte list ordered as little endian.
BYTE-WIDTH specifies INTEGER's byte-width."
  (if (eq byte-width 0)
      nil
    (cons (calcFunc-and normalized #xff)
	  (yabin--get-bytes-le
	   (calcFunc-rsh normalized 8)
	   (1- byte-width)))))


;; (defun yabin-pack (integer byte-width &optional byte-order)
;;   (yabin--local-env
;;    ((integer (yabin--normalize integer))
;;     result
;;     (bytes-be (dotimes (c byte-width result)
;; 		(push (calcFunc-and integer #xff) result)
;; 		(setq integer (calcFunc-rsh integer 8)))))
;;    (apply 'vector (if (eq ?l (or byte-order (byteorder)))
;; 		      (nreverse bytes-be)
;; 		     bytes-be))))

(defun yabin-number-to-unibyte-string (integer byte-width &optional byte-order)
  "Convert INTEGER into unibyte string.
BYTE-WIDTH specifies INTEGER's byte-width.
The result string's order is decided by BYTE-ORDER parameter:

66  (?B - ascii uppercase B) - big endian.  Ordered from higher to lower.
108 (?l - ascii lowercase l) - little endian.  Ordered from lower to higher.

If BYTE-ORDER is nil, system value (result of `byteorder') is used."
  (let* ((bytes (yabin-pack integer byte-width byte-order))
	 (len (length bytes))
	 (str (make-string len 0)))
    (dotimes (pos len str)
      (aset str pos (aref bytes pos)))))

(defun yabin-unpack (sequence &optional unsigned-p byte-order)
  "Convert SEQUENCE into integer.
SEQUENCE must be consisted by 8-bit integer.
If UNSIGNED-P is non-nil, the result is converted into unsigned integer.
SEQUENCE order is specified by BYTE-ORDER parameter:

66  (?B - ascii uppercase B) - big endian.  Ordered from higher to lower.
108 (?l - ascii lowercase l) - little endian.  Ordered from lower to higher.

If BYTE-ORDER is nil, system value (result of `byteorder') is used."
  (yabin-clip
   (yabin--local-env
    nil
    (yabin--combine-bytes-le (if (eq ?B (or byte-order (byteorder)))
				 (reverse (mapcar 'identity sequence))
			       (mapcar 'identity sequence))))
   (* 8 (length sequence))
   unsigned-p))

(defun yabin--combine-bytes-le (bytes)
  "Convert BYTES list into integer.
BYTES must be consisted by 8-bit integer ordered as little endian."
  (if (null bytes)
      0
    (math-add (logand #xff (car bytes))
	      (math-mul #x100 (yabin--combine-bytes-le (cdr bytes))))))

(defalias 'yabin-unibyte-string-to-number 'yabin-unpack)

;; predicates

(defun yabin-numberp (object)
  "Return t if OBJECT is a number (floating point or integer)."
  (yabin--local-env nil (yabin--predicate object)))

(defun yabin-natnump (object)
  "Return t if OBJECT is a nonnegative integer."
  (yabin--local-env nil (yabin--predicate object 'math-natnump)))

(defun yabin-integerp (object)
  "Return t if OBJECT is an integer."
  (yabin--local-env nil (yabin--predicate object 'math-integerp)))

(defun yabin-oddp (object)
  "Return t if OBJECT is odd integer."
  (yabin--local-env nil (yabin--predicate object 'math-oddp)))

(defun yabin-evenp (object)
  "Return t if OBJECT is even integer."
  (yabin--local-env nil (yabin--predicate object 'math-evenp)))

(defun yabin-posp (object)
  "Return t if OBJECT is positive number without zero."
  (yabin--local-env nil (yabin--predicate object 'math-posp)))

(defun yabin-negp (object)
  "Return t if OBJECT is negative number."
  (yabin--local-env nil (yabin--predicate object 'math-negp)))

(defun yabin-floatp (object)
  "Return t if OBJECT is a floating point number."
  (yabin--local-env nil (yabin--predicate object 'math-floatp 'math-infinitep)))

(defun yabin-zerop (object)
  "Return t if OBJECT is zero."
  (yabin--local-env nil (yabin--predicate object 'math-zerop)))

(defun yabin-isnan (object)
  "Return t if OBJECT is a NaN."
  (yabin--local-env
   nil
   (yabin--predicate object (lambda (v)
			      (or (equal v yabin--math-pnan)
				  (equal v yabin--math-nnan))))))

(defun yabin-isinf (object)
  "Return t if OBJECT is infinite."
  (and (yabin--local-env
	nil
	(yabin--predicate object 'math-infinitep))
       (not (yabin-isnan object))))

;; comparators

(defun yabin-equal (num1 num2)
  "Return t if NUM1 and NUM2 are equal."
  (yabin--local-env nil (yabin--funcall-no-format 'math-equal num1 num2)))

(defun yabin-not-equal (num1 num2)
  "Return t if NUM1 and NUM2 are not equal."
  (not (yabin-equal num1 num2)))

(defun yabin-less-than (num1 num2)
  "Return t if NUM1 is less than NUM2."
  (yabin--local-env nil (yabin--funcall-no-format 'math-lessp num1 num2)))

(defun yabin-less-than-equal (num1 num2)
  "Return t if NUM1 is less than or equal to NUM2."
  (or (yabin-less-than num1 num2)
      (yabin-equal num1 num2)))

(defun yabin-greater-than (num1 num2)
  "Return t if NUM1 is greater than NUM2."
  (yabin-less-than num2 num1))

(defun yabin-greater-than-equal (num1 num2)
  "Return t if NUM1 is greater than or equal to NUM2."
  (or (yabin-greater-than num1 num2)
      (yabin-equal num1 num2)))


;; formatting

(defun yabin--decode-format-string (format-string)
  "Convert FORMAT-STRING into `yabin-format' parameter."
  (save-match-data
    (unless (string-match
	     "^%\\([-+ #0]*\\)\\([0-9]*\\)\\(?:\\.\\([0-9]+\\)\\)?\\([doxXgGeEf]\\)$"
	     format-string)
      (error "Invalid format operation %s" format-string))
    
    (let ((headers (string-to-list (match-string 1 format-string)))
	  (width (match-string 2 format-string))
	  (precision (match-string 3 format-string))
	  (form (string-to-char (match-string 4 format-string)))
	  spec-plist)
      
      (setq spec-plist
	    (plist-put spec-plist :form
		       (cond
			((eq form ?d) 'decimal)
			((eq form ?o) 'octal)
			((eq form ?x) 'hex)
			((eq form ?X) 'hex)
			((eq form ?f) 'decimal-point)
			((eq form ?e) 'exponential)
			((eq form ?E) 'exponential)
			((eq form ?g) 'float)
			((eq form ?G) 'float))))
      (when (memq form '(?X ?E ?G))
	(setq spec-plist (plist-put spec-plist :upcase t)))
      (when (and width (not (zerop (length width))))
      	(setq spec-plist (plist-put spec-plist :width (string-to-number width))))
      (when (and precision (not (zerop (length precision))))
      	(setq spec-plist (plist-put spec-plist :precision (string-to-number precision))))
      (when (memq ?# headers)
	(setq spec-plist (plist-put spec-plist :special t)))
      (when (memq ?- headers)
	(setq spec-plist (plist-put spec-plist :align 'left)))
      (when (memq ?  headers)
	(setq spec-plist (plist-put spec-plist :sign 'space)))
      (when (memq ?+ headers)
	(setq spec-plist (plist-put spec-plist :sign t)))
      (when (memq ?0 headers)
	(setq spec-plist (plist-put spec-plist :zero-padding t)))

      spec-plist
      )
    ))

(defun yabin-format (format-string value)
  "Format VALUE according to FORMAT-STRING like `format'.
This is able to format only one number at once. See document of `format'
for detail."
  (apply 'yabin-format-spec value (yabin--decode-format-string format-string)))

(defun yabin-format-spec (value &rest specs)
  "Format string-number VALUE according to specification of SPECS.
Tha next available specification properties:

:sign FLAG -- treatment of number's sign part.
  t      - print sign.
  nil    - print sign only when number is negative.
  'space - print sign. but when number is positive, print blank.

:zero-ppading BOOL -- zero padding flag used when VALUE's width is
shorten than specified by `:width'.
  t   - print '0'.
  nil - print blank.

:align ALIGN -- number alignment used when VALUE's width is shorten
than specified by `:width'.
  'right - align right. default behavior.
  'left  - align left. when enabled this, `:zero-padding' is ignored.

:special FLAG -- special formatting. it's a different behavior by notation.
  t   - if radix is 16, print leading '0x'; if radix is 8, print leading '0';
if `:form' is any 'decimal-point, 'exponential or 'float, it causes a decimal
point '.' to be included even if the precision is zero.
  nil - do nothing.

:form TYPE -- number's notation.
  decimal       - decimal.
  octal         - octal. same as `:radix 8'.
  hex           - hex. same as `:radix 16'.
  decimal-point - decimal point notation like '0.000012'.
  exponential   - exponential notation like '0.31e003'.
  float         - decimal-point or exponential, whichever uses fewer characters.

:upcase -- using upper case alphabet. this is only affect when radix is over 10,
exponential form, or float form type.
  t   - upper case. (ex: 0X3F, 0.31E+010)
  nil - lower case. (ex: 0xa9, 1,98e-001)

:radix NUMBER -- converting into specified base radix when VALUE is integer.

:width NUMBER -- lower limit for the length of the printed number.

:precision NUMBER -- for decimal-point, exponential or float notation, the number
after the '.' in the precision specifier says how many decimal places to show;
if zero, the decimal point itself is omitted.
for decimal, octal or hex notation, lower limit for length of the number."
    (yabin--local-env
     (
      ;; :sign => t, nil, 'space
      (sign (plist-get specs :sign))
      ;; :zero-padding => t or nil
      (zero-padding (plist-get specs :zero-padding))
      ;; :align => 'left or other(align right)
      (leftify (eq (plist-get specs :align) 'left))
      ;; :special => t or nil
      (special (plist-get specs :special))
      ;; :form => 'decimal, 'octal, 'hex, 'float, 'decimal-point, 'exponential
      (form (or (plist-get specs :form)
		(when (yabin-integerp value) 'decimal)
		'float))
      (form-decimalp (memq form '(decimal octal hex)))
      (form-floatp (memq form '(float decimal-point exponential)))
      ;; :witth => number
      (width (or (plist-get specs :width) 0))
      ;; :precision => number
      (precision (plist-get specs :precision))
      ;; :radix => number
      (radix (or (plist-get specs :radix)
		 (when (eq form 'octal) 8)
		 (when (eq form 'hex) 16)
		 (when form-floatp 10)
		 10))
      ;; :upcase => t or nil
      (upcase (plist-get specs :upcase))

      ;; override calc-environment
      (calc-internal-prec (max (or precision 0) yabin-internal-prec))
      (calc-float-format (list 'fix (or precision yabin--default-format-precision)))
      (calc-number-radix radix)
      (math-radix-explicit-format nil)
      (calc-radix-formatter (lambda (rad num) (format "%s" num)))

      ;; presentation values
      (number (yabin--normalize value))
      
      (header (concat
	       (cond ((math-lessp number 0) "-")
		     ((eq sign 'space) " ")
		     (sign "+"))
	       (if special
		   (cond ((eq radix 16) "0x")
			 ((eq radix 8) "0")))))
      (body (if form-decimalp
		;; decimal/octal/hex
		(yabin--to-string (if (math-infinitep number)
				      0 ; nan/inf value.
				    (math-abs (math-trunc number))))
	      ;; float/decimal-point/exponential
	      (let* ((float-number (math-abs (math-float number)))
		     (mant (calcFunc-mant float-number))
		     (xpon (calcFunc-xpon float-number))
		     (float-precision (cadr calc-float-format)))
		
		;; NOTE: the nan value from `format' is depend by system, but
		;; yabin uses "nan" and "inf" literal.
		(if (math-infinitep number)
		    (progn
		      (setq zero-padding nil)
		      (cond
		       ((member number (list yabin--math-pnan yabin--math-nnan))
			"nan")
		       (t
			"inf")))
		  ;; not a nan/inf
		  (when (or (eq form 'decimal-point)
			  (and (eq form 'float)
			       (math-lessp xpon (car yabin-exponential-form-threshold))
			       (math-lessp (cdr yabin-exponential-form-threshold) xpon)))

			(when (eq form 'float)
			  (setq float-precision (+ float-precision
						   (math-neg xpon))))
			(setq mant float-number)
			(setq xpon nil))
		  
		  (when (eq form 'float)
		    (setq float-precision (+ float-precision
					     (if (or (eq float-precision 0)
						     (math-zerop mant))
						 0 -1)))
		    (setq calc-float-format (list 'fix float-precision)))
		
		  (concat 
		   ;; mantissa
		   (progn
		     (setq mant (math-round mant float-precision))
		     (cond
		      ((eq form 'float)
		       (if special
			   (if (and (math-zerop mant) (eq precision 0))
			       "0.0"
			     (yabin--to-string (math-float mant)))
			 (if (math-zerop mant) ; ignore precision
			     "0"
			   (save-match-data (replace-regexp-in-string
					     "\\.?0*$" "" (yabin--to-string (math-float mant)))))
			 ))
		      (t
		       (if (not (and (math-zerop mant) (eq precision 0)))
			   (yabin--to-string (math-float mant))
			 (if special "0." "0")))))
		 		 
		   ;; exponential
		   (when xpon
		     (let* ((xpon-body (math-format-number (math-abs xpon)))
			    (xpon-pad (max 0 (- 3 (length xpon-body)))))
		       (concat
			(if upcase "E" "e")
			(if (math-negp xpon) "-" "+")
			(make-string xpon-pad ?0)
			xpon-body)))
		   )))))
      (prec-pad-len (if (and form-decimalp precision)
			(max 0 (- precision (length body)))
		      0))
      (pad-len (- width (+ (length header)
			   prec-pad-len
			   (length body)))))
    
     ;; combine header, padding, body
     (setq body
	   (cond
	    ((<= pad-len 0)
	     (concat header (make-string prec-pad-len ?0) body))
	    (leftify
	     (concat header (make-string prec-pad-len ?0) body (make-string pad-len ? )))
	    ((and zero-padding (null precision))
	     (concat header (make-string pad-len ?0) body))
	    (t
	     (concat (make-string pad-len ? ) header (make-string prec-pad-len ?0) body))))
     (if (not upcase)
	 (downcase body)
       body)
     ))

;; install aliases

(let ((alias-alist '((+ . yabin-add)
		     (- . yabin-sub)
		     (* . yabin-multi)
		     (/ . yabin-div)
		     (% . yabin-reminder)
		     (1+ . yabin-add1)
		     (1- . yabin-sub1)
		     (> . yabin-greater-than)
		     (>= . yabin-greater-than-equal)
		     (< . yabin-less-than)
		     (<= . yabin-less-than-equal)
		     (= . yabin-equal)
		     (/= . yabin-not-equal)
		     (^ . yabin-expt))))
  ; pickup yabin-FUNC
  (mapatoms (lambda (sym)
	      (let ((name (symbol-name sym)))
		(if (and (functionp sym)
			 (string-match "^yabin-\\([^-].*\\)$"
				       name))
		    (push (cons (match-string 1 name)
				sym) alias-alist)))))


  ; map yabin-FUNC => !FUNC
  (mapc (lambda (fns)
	  (defalias (intern (format "!%s" (car fns)))
	    (cdr fns))) alias-alist)
  )

(provide 'yabin)

;;; yabin.el ends here
