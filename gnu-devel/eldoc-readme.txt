This program was inspired by the behavior of the "mouse documentation
window" on many Lisp Machine systems; as you type a function's symbol
name as part of a sexp, it will print the argument list for that
function.  Behavior is not identical; for example, you need not actually
type the function name, you need only move point around in a sexp that
calls it.  Also, if point is over a documented variable, it will print
the one-line documentation for that variable instead, to remind you of
that variable's meaning.

This mode is now enabled by default in all major modes that provide
support for it, such as `emacs-lisp-mode'.
This is controlled by `global-eldoc-mode'.

Major modes for other languages may use ElDoc by adding an
appropriate function to the buffer-local value of
`eldoc-documentation-functions'.