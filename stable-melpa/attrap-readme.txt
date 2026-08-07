Attrap! provides a command to attempt to fix the flycheck error at point.

Users: Invoke the command `attrap-attrap' when point is on a
flycheck or flymake error, and check the results.  (If several
fixes apply you will be asked which one to apply.) Attrap!
currently comes with builtin fixers for haskell (GHC messages),
elisp, latex and a generic eglot redirect.

Configuration: `attrap-flymake-backends-alist' is an alist from
flymake backend to attrap fixer.  `attrap-flycheck-checkers-alist'
is an alist from flycheck checker symbol to attrap fixer.  All the
See below for the definition of a fixer.

A fixer is a element is a side-effect-free function mapping an
error message MSG to a list of options.  An option is a cons of a
description and a repair.  (Thus a list of options is an alist.)
The repair is a function of no argument which is meant to apply one
fix suggested by MSG in the current buffer, at point.  The
description is meant to be a summarized user-facing s-expr which
describes the repair.  This description can be used for example for
selecting the best repair.  An option can be conveniently defined
using `attrap-option'.  A singleton option list can be conveniently
defined using `attrap-one-option'.
