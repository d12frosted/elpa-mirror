Monitor provides utilities for monitoring expressions.
A predicate-based system is used to determine when to run
specific functions - not unlike Emacs' built-in hooks (see Info node `Hooks').

For example, if we wanted to print "foo" every time the value
of (point) changed in the current buffer, we could write:

   (monitor-expression-value (point) (lambda () (print "foo")))

A (rather convoluted) way of mimicking the functionality of the
standard `after-change-major-mode-hook' could be to use the
following expression:

   (monitor-expression-value major-mode (...))

Which would run whenever the value of `major-mode' changed.
