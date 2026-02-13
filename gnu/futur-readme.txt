A library to try and make async programming a bit easier.
This is inspired from Javscript's async/await, Haskell's monads,
and ConcurrentML's events.

You can create trivial futures with `futur-done'.
You can create a "process future" with `futur-process-call'.
And the main way to use futures is to compose them with `futur-let*',
which can be used as follows:

    (futur-let*
        ((buf (current-buffer))
         (exitcode1 <- (futur-process-call CMD1 nil buf nil ARG1 ARG2))
         (out (with-current-buffer buf
                (buffer-string)))  ;; Get the process's output.
         (exitcode2 <- (futur-process-call CMD2 nil buf nil ARG3 ARG4)))
      (with-current-buffer buf
        (buffer-string)))

This example builds a future which runs two commands in sequence.
For those rare cases where you really do need to block everything
else and wait for a future to complete, you can
use`futur-blocking-wait-to-get-result'.

Low level API

- (futur-done VAL) to create a trivial future returning VAL.
- (futur-error ERR) to create a trivial failed future.
- (futur-new FUN) to create a non-trivial future.
  FUN is called with one argument (the new `futur' object) and should
  return the "blocker" that `futur' is waiting for (used mostly
  when aborting a future).
- (futur-abort FUTUR): Aborts execution of FUTUR.
- (futur-deliver-value FUTUR VAL): Mark FUTUR as having completed
  successfully with VAL, and runs the clients waiting for that event.
- (futur-deliver-failure FUTUR ERROR): Mark FUTUR as having failed
  with ERROR, and runs the clients waiting for that event.
- (futur-register-callback FUTUR FUN): Register FUN as a client.
  Will be called with two arg (the ERROR and the VAL) when FUTURE completes.
- (futur-blocking-wait-to-get-result FUTUR): Busy-wait for FUTUR to complete
  and return its value.  Better use `futur-bind' or `futur-let*' instead.
  BEWARE: Please don't use it unless you really absolutely have to.

Composing futures

- (futur-bind FUTUR FUN &optional ERROR-FUN): Builds a new future which
  waits for FUTUR to completes and then calls FUN (or ERROR-FUN) with the
  resulting value (or its error).  (ERROR-)FUN should itself return
  a future, tho if it doesn't it's automatically turned into a trivial one.
- (futur-let* BINDINGS [:error-fun ERROR-FUN] BODY): Macro built on top
  of `futur-bind' which runs BINDINGS in sequence and then runs BODY.
  Each BINDING can be either a simple (PAT EXP) that is executed
  as in a `pcase-let*' or a (PAT <- FUTUR) in which case the rest is
  delayed until FUTUR completes.
- (futur-list &rest FUTURS): Run FUTURS concurrently and return the
  resulting list of values.

Related packages

- [deferred](https://melpa.org/#/deferred): Provides similar functionality.
  Maybe the only reason `futur.el' exists is because `deferred' is different
  from what I expected (NIH syndrome?).
- [promise](https://melpa.org/#/promise) is a very similar library,
  which tries to stay as close as possible to JavaScript's promises,
  leading to a very non-idiomatic implementation in `promise-core.el'.
  TODO: We only provide the core functionality of `promise', currently
  and it would make sense to add most of the rest, or even provide
  a bridge between the two.
- [pfuture](https://melpa.org/#/pfuture): Sounds similar, but is more
  of a wrapper around `make-process'.  Compared to this package,
  `pfuture' does not try very hard to help compose async computations
  and to propagate errors.
- [async](http://elpa.gnu.org/packages/async.html): A package that focuses
  on executing ELisp code concurrently by launching additional Emacs
  (batch) sessions.
  TODO: It would make a lot of sense to allow use of `async'
  via `futur' objects.
- [async-await](https://melpa.org/#/async-await): This provides
  JavaScript-style async/await operators on top of the `promise' package.
  This fundamentally require a kind of CPS conversion of the code, for
  which they use `generator.el'.
  TODO: It would be possible to make `async-await' work on top of `futur',
  but to the extent that `generator.el' is not able to perform CPS
  correctly in all cases (because it's hard/impossible in general),
  I'm not sure it's a good idea to encourage this coding style.
  Maybe instead we should develop some way to detect&flag most of the
  pitfalls of the current style (such as using `progn' instead of
  `future-let*' to sequence execution when one part is a future).
- [aio](https://melpa.org/#/aio): Also provides await/async style
  coding (also using `generator.el' under the hood) but using its
  own (much simpler) "promise" objects.
- [async1](https://melpa.org/#/async1): A more limited/ad-hoc solution to
  the problem that async/await try to solve that hence avoids the need
  to perform CPS.  Not sure if it's significantly better than `futur-let*'.
- [asyncloop](https://melpa.org/#/asyncloop): Focuses on just
  running a sequence of function calls with regular "stops" in-between
  to let other operations happen "concurrently".
- [async-job-queue](https://melpa.org/#/async-job-queue):
- [pdd](https://melpa.org/#/pdd): HTTP library that uses its own
  implementation of promises.