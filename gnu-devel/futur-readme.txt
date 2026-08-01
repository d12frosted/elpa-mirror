Futur is a library to try and make async programming a bit easier.
It is inspired from Javscript's async/await, Haskell's monads,
and ConcurrentML's events.

You can create trivial futures with `futur-done`.
You can create a "process future" with `futur-process-call`.
And the main way to use futures is to compose them with `futur-let*`,
which can be used as follows:

    (futur-let*
        ((buf (current-buffer))
         (exitcode1 <- (futur-process-call CMD1 nil buf nil ARG1 ARG2))
         (out (with-current-buffer buf
                (buffer-string)))  ;; Get the process's output.
         (exitcode2 <- (futur-process-call CMD2 nil buf nil ARG3 ARG4)))
      (with-current-buffer buf
        (concat out (buffer-string))))

This example builds a future which runs two commands in sequence.
For those rare cases where you really do need to block everything
else and wait for a future to complete, you can
use `futur-blocking-wait-to-get-result`.

The minor more `futur-hacks-mode` inserts itself into a few Emacs
features to make them use futures.  The intention is for those to
eventually get integrated directly into Emacs or be dropped, but it is
also meant as a testbed for the library.

## Low level API

- `(futur-done VAL)`: Create a trivial future returning VAL.
- `(futur-failed ERR)`: Create a trivial failed future.
- `(futur-new FUN)`: Create a non-trivial future.
  FUN is called with one argument (the new `futur` object) and should
  return the "blocker" that `futur` is waiting for (used mostly
  when aborting a future).  FUN is expected to launch the computation
  of the future and arrange to call one of `futur-deliver-*` once it's done.
- `(futur-deliver-value FUTUR VAL)`: Mark FUTUR as having completed
  successfully with VAL, and runs the clients waiting for that event.
- `(futur-deliver-failure FUTUR ERROR)`: Mark FUTUR as having failed
  with ERROR, and runs the clients waiting for that event.
- `(futur-abort FUTUR REASON)`: Abort execution of FUTUR.
- `(futur-catch-abort HANDLER FUTUR)`: Return a future that
  behaves like FUTUR but caches abortions such that FUTUR is
  not affected.
  While errors propagate "down/out"ward from a future to its clients,
  abortions propagate "up/in"ward from a client to the futures on which
  it depends.
- `(futur-blocking-wait-to-get-result FUTUR)`: Busy-wait for FUTUR to complete
  and return its value.  Better use `futur-bind` or `futur-let*` instead.
  BEWARE: Please don't use it unless you really absolutely have to.

## Composing futures

- `(futur-bind FUTUR FUN &optional ERROR-FUN)`: Build a new future which
  waits for FUTUR to complete and then calls FUN (or ERROR-FUN) with the
  resulting value (or its error).  (ERROR-)FUN should itself return
  a future, tho if it doesn't it's automatically turned into a trivial one.
- `(futur-let* BINDINGS [:on-error HANDLER] BODY)`: Macro built on top
  of `futur-bind` which runs BINDINGS in sequence and then runs BODY.
  Each BINDING can be either a simple `(PAT EXP)` that is executed
  as in a `pcase-let*` or a `(PAT <- FUTUR)` in which case the rest is
  delayed with `futur-bind` until FUTUR completes.
- `(futur-list &rest FUTURS)`: Run FUTURS concurrently and return a future
  which will hold the resulting list of values (or the first error).
- `(futur-race &rest FUTURS)`: Run FUTURS concurrently, return a future
  which will hold the first result, and discard the rest.

## Predefined future constructors

- `(futur-funcall FUNC &rest ARGS)`:
  Like `funcall`, but runs the code asynchronously.
- `(futur-timeout TIME)`
- `(futur-sit-for TIME)`
- `(futur-process-call PROG &optional INFILE DESTINATION _DISPLAY &rest ARGS)`:
  Like `call-process` but asynchronous, thus allows parallelism between
  Emacs and the subprocess.
- `(futur-with-temp-buffer &rest BODY)`
- `(futur-unwind-protect FORM &rest FORMS)`
- `(futur-concurrency-bound FUNC &rest ARGS)`:
  Like `futur-funcall` but throttles execution to avoid running too
  many tasks concurrently.

## Running ELisp concurrently in subprocesses

- `(futur-elisp-funcall INITIAL-CONTEXT FUNC &rest ARGS)`:
  Like `futur-funcall` but runs the code in parallel in a subprocess.
- `(futur-elisp-sandbox--funcall INITIAL-CONTEXT FUNC &rest ARGS)`:
  Like `futur-elisp-funcall` but runs the code in a sandbox so it
  can be used with untrusted code.

## Related packages

- [deferred](https://melpa.org/#/deferred): Provides similar functionality.
  Maybe the only reason `futur.el` exists is because `deferred` is different
  from what I expected (NIH syndrome?).
- [async](http://elpa.gnu.org/packages/async.html): A package that focuses
  on executing ELisp code concurrently by launching additional Emacs
  (batch) sessions.  `futur-elisp.el` also provides that functionality
  but tries to make it more efficient by re-using subprocesses to avoid
  paying each time the cost of launching a new subprocess.
- [promise](https://melpa.org/#/promise) tries to stay as close as possible
  to JavaScript's promises, leading to a very non-idiomatic implementation
  in `promise-core.el`.
- [pfuture](https://melpa.org/#/pfuture): Sounds similar, but is more
  of a wrapper around `make-process`.  Compared to this package,
  `pfuture` does not try very hard to help compose async computations
  and to propagate errors.
- [async-await](https://melpa.org/#/async-await): This provides
  JavaScript-style async/await operators on top of the `promise` package.
  This fundamentally require a kind of CPS conversion of the code, for
  which they use `generator.el`.
  TODO: It would be possible to make `async-await` work on top of `futur`,
  but to the extent that `generator.el` is not able to perform CPS
  correctly in all cases (because it's hard/impossible in general),
  I'm not sure it's a good idea to encourage this coding style.
  Maybe instead we should develop some way to detect&flag most of the
  pitfalls of the current style (such as using `progn` instead of
  `future-let*` to sequence execution when one part is a future).
- [aio](https://melpa.org/#/aio): Also provides await/async style
  coding (also using `generator.el` under the hood) but using its
  own "promise" objects, which are much simpler than those of `promise.el`.
- [async1](https://melpa.org/#/async1): A more limited/ad-hoc solution to
  the problem that async/await try to solve that hence avoids the need
  to perform CPS.  Can be seen as `futur-let*` on steroids.
  Not sure if it's significantly better than `futur-let*`.
- [asyncloop](https://melpa.org/#/asyncloop): Focuses on just
  running a sequence of function calls with regular "stops" in-between
  to let other operations happen "concurrently".
- [async-job-queue](https://melpa.org/#/async-job-queue):
- [pdd](https://melpa.org/#/pdd): HTTP library that uses its own
  implementation of promises.
- [el-job](https://elpa.gnu.org/packages/el-job.html): Library to run ELisp
  jobs in parallel in several Emacs subprocesses.
  `futur-elisp/server.el` took some inspiration from that package.

## BUGS

- Debugging the asynchronous code is a PITA compounded by bugs and
  limitations of ELisp threads (see for example bug#80286 and bug#80537,
  and if you prefer to set `futur--use-threads` to nil you may
  suffer from bug#80468 instead).
  Also, there is no support for single-stepping with Edebug through
  the code running in an ELisp subprocess.
- Sometimes the `futur--background` thread gets blocked on some
  operation (e.g. entering the debugger), which blocks all further
  execution of async tasks.
- When launching elisp/sandbox servers (or during `futur-reset-context`),
  the client receives and displays all the `message`s from the subprocess,
  which can be more annoying than helpful.

