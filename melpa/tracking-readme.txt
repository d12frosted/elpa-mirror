tracking.el is a library for other Emacs Lisp programs not useful
by itself.

The library provides a way to globally register buffers as being
modified and scheduled for user review. The user can cycle through
the buffers using C-c C-SPC. This is especially useful for buffers
that interact with external sources, such as chat clients and
similar programs.
