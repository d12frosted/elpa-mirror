`aio` is to Emacs Lisp as [`asyncio`][asyncio] is to Python. This
package builds upon Emacs 25 generators to provide functions that
pause while they wait on asynchronous events. They do not block any
thread while paused.

The main components of this package are `aio-defun' / `aio-lambda'
to define async function, and `aio-await' to pause these functions
while they wait on asynchronous events. When an asynchronous
function is paused, the main thread is not blocked. It is no more
or less powerful than callbacks, but is nicer to use.

This is implementation is based on Emacs 25 generators, and
asynchronous functions are actually iterators in disguise, operated
as stackless, asymmetric coroutines.
