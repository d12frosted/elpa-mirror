
Suppose the point is on some number.  If you want to double it,
invoke `operate-on-number-at-point' followed by some keys: * 2 RET.

Alternatively, you can bind `apply-operation-to-number-at-point' to
<some prefix> *, and you will be able to just type the sequence to
double a number, which function uses the last key typed as function
specifier and supplies with a default argument which in this case
of * is 2.  This command takes numeric argument, so you can type
M-3 <some prefix> * to triple the number.

For the predefined operation list and how to define a new
operation, see `operate-on-number-at-point-alist'.

It is recommended using smartrep to bind the functions like this:

  (smartrep-define-key global-map "C-."
    '(("+" . apply-operation-to-number-at-point)
      ("-" . apply-operation-to-number-at-point)
      ("*" . apply-operation-to-number-at-point)
      ("/" . apply-operation-to-number-at-point)
      ("\\" . apply-operation-to-number-at-point)
      ("^" . apply-operation-to-number-at-point)
      ("<" . apply-operation-to-number-at-point)
      (">" . apply-operation-to-number-at-point)
      ("#" . apply-operation-to-number-at-point)
      ("%" . apply-operation-to-number-at-point)
      ("'" . operate-on-number-at-point)))
