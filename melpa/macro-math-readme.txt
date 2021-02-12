
Add the following to your .emacs file:

(require 'macro-math)
(global-set-key "\C-x~" 'macro-math-eval-and-round-region)
(global-set-key "\C-x=" 'macro-math-eval-region)

At any time, especially during macros, add an expression to the buffer and
mark it.  Then call `macro-math-eval-region' to get the result.

A few example expressions:
5 + 3
(2 + 3) * 5
1/2 * pi

For example, use it to increase all numbers in a buffer by one.
Call `kmacro-start-macro', move the point behind the next number, type "+ 1",
mark the number and + 1, call `macro-math-eval-region'.  Finish the macro
with `kmacro-end-macro', then call it repeatedly.

; Change Log ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

2009-03-09 (1.0)
   Symbols names (like pi or e) can now be evaluated.
   `macro-math-eval-region' accepts a numeric prefix now.
   Changed back-end to `calc-eval'.

2007-04-10 (0.9)
   Initial release.
