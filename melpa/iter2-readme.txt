Fully compatible fast reimplementation of `generator' built-in
Emacs package.  This library provides `iter2-defun` and
`iter2-lambda` forms that can be used in place of `iter-defun` and
`iter-lambda`.  Form `iter2-next` is a replacement for `iter-next`
(see its documentation for the reasons), though `iter-next` will
work too.

Other functions and macros (`iter-yield`, `iter-yield-from`,
`iter-do` and `iter-close`) are intentionally not duplicated: just
use the ones from the original package.
