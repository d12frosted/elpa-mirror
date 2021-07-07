test-simple.el is:

* Simple.  No need for
  - context macros,
  - enclosing specifications,
  - required test tags.

  But if you want, you still can enclose tests in a local scope,
  add customized assert failure messages, or add summary messages
  before a group of tests.

* Accommodates both interactive and non-interactive use.
   - For interactive use, one can use `eval-last-sexp', `eval-region',
     and `eval-buffer'.  One can `edebug' the code.
   -  For non-interactive use, run:
       emacs --batch --no-site-file --no-splash --load <test-lisp-code.el>

Here is an example using gcd.el found in the examples directory.

  (require 'test-simple)
  (test-simple-start) ;; Zero counters and start the stop watch.

  ;; Use (load-file) below because we want to always to read the source.
  ;; Also, we don't want no stinking compiled source.
  (assert-t (load-file "./gcd.el")
	      "Can't load gcd.el - are you in the right directory?" )

  (note "degenerate cases")

  (assert-nil (gcd 5 -1) "using positive numbers")
  (assert-nil (gcd -4 1) "using positive numbers, switched order")
  (assert-raises error (gcd "a" 32)
                 "Passing a string value should raise an error")

  (note "GCD computations")
  (assert-equal 1 (gcd 3 5) "gcd(3,5)")
  (assert-equal 8 (gcd 8 32) "gcd(8,32)")
  (end-tests) ;; Stop the clock and print a summary

Edit (with Emacs of course) gcd-tests.el and run M-x eval-current-buffer

You should see in buffer *test-simple*:

   gcd-tests.el
   ......
   0 failures in 6 assertions (0.002646 seconds)

Now let us try from a command line:

   $ emacs --batch --no-site-file --no-splash --load gcd-tests.el
   Loading /src/external-vcs/emacs-test-simple/example/gcd.el (source)...
   *scratch*
   ......
   0 failures in 6 assertions (0.000723 seconds)
