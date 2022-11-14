This package aims to allow Common Lisp code to be run from within
Emacs Lisp.  SLIME/SLY must be connected before invoking the
functions.  Configuration of SLIME/SLY and CL is up to the user.
The thread-creating functions can be used to augment Emacs with
threads that run in Common Lisp.  Since it is possible to update
the Emacs side from within the threads, one can use it to offload
long-running processes to CL and retain a responsive Emacs.

(eval-in-emacs) function is injected to CL side to allow calls to
Emacs side to be independent of interaction-mode (SLIME or SLY)
