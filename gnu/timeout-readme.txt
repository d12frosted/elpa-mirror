1 Timeout: Sometimes Emacs needs one
════════════════════════════════════

  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

  *Breaking Change*: This library is being upstreamed into Emacs.  For
   consistency with Elisp naming guidelines, the names of the functions
   have been changed, and the version has been bumped to v2.0.  Sorry
   about that.

  The naming changes are:
  ┌────
  │ timeout-throttle  -> timeout-throttled-func
  │ timeout-throttle  -> timeout-throttled-func
  │ timeout-throttle! -> timeout-throttle
  │ timeout-throttle! -> timeout-throttle
  └────

  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

  `timeout' is a small library to help you throttle or debounce elisp
  function calls.  See [this write-up] for an introduction and potential
  uses.

  It's actually tiny, just a couple of functions.


[this write-up] <https://karthinks.com/software/cool-your-heels-emacs>

1.0.1 To use this library:
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can throttle an elisp function `func' to run at most once every 2
  seconds:
  ┌────
  │ (timeout-throttle 'func 2.0)
  └────

  To reset `func':
  ┌────
  │ (timeout-throttle 'func 0.0)
  └────

  When the call is a noop, a throttled function will return the same
  result as the last successful run.

  You can debounce an elisp function `func' to run after an
  uninterrupted delay of 0.5 seconds:
  ┌────
  │ (timeout-debounce 'func 0.5)
  └────

  To reset `func':
  ┌────
  │ (timeout-debounce 'func 0.0)
  └────

  By default a debounced function returns `nil' at call time.  To change
  this, run:
  ┌────
  │ (timeout-debounce 'func 0.5 'some-return-value)
  └────

  Instead of advising `func', you can also create new throttled or
  debounced versions of it with `timeout-throttle' and
  `timeout-debounce':

  ┌────
  │ (timeout-throttled-func 'func 2.0)
  │ (timeout-debounced-func 'func 0.5)
  └────

  These return anonymous functions which you can bind to a symbol with
  `defalias' or `fset':
  ┌────
  │ (defalias 'throttled-func (timeout-throttled-func 'func 2.0))
  │ (fset     'throttled-func (timeout-throttled-func 'func 2.0))
  └────


1.0.2 Dynamic duration
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  All timeout functions support dynamic duration by passing a symbol or
  function instead of a number:

  ┌────
  │ ;; Using a variable for dynamic timeout
  │ (defvar my-timeout 1.5)
  │ (timeout-throttle 'func 'my-timeout)  ; uses value of my-timeout
  │ 
  │ ;; Using a function for conditional behavior
  │ (timeout-throttle 'func (lambda () (if busy-p 0.1 2.0)))
  │ 
  │ ;; The duration is evaluated at runtime, so you can change it dynamically
  │ (setq my-timeout 3.0)  ; throttle duration is now 3 seconds
  └────

  When passed a symbol, its value is used as the duration. When passed a
  function, it is called with no arguments to get the duration. This
  allows for adaptive timeouts based on system state or user
  preferences.
