timeout is a small Elisp library that provides higher order functions to
throttle or debounce Elisp functions.  This is useful for corralling
over-eager code that:
(i) is slow and blocks Emacs, and
(ii) does not provide customization options to limit how often it runs,

To throttle a function FUNC to run no more than once every 2 seconds, run
(timeout-throttle 'func 2.0)

To debounce a function FUNC to run after a delay of 0.3 seconds, run
(timeout-debounce 'func 0.3)

To create a new throttled or debounced version of FUNC instead, run

(timeout-throttled-func 'func 2.0)
(timeout-debounced-func 'func 0.3)

You can bind this via fset or defalias:

(defalias 'throttled-func (timeout-throttled-func 'func 2.0))
(fset     'throttled-func (timeout-throttled-func 'func 2.0))

Dynamic duration is supported by passing a symbol or function instead of
a number:

(defvar my-timeout 1.5)
(timeout-throttle 'func 'my-timeout)  ; uses value of my-timeout
(timeout-throttle 'func (lambda () (if busy-p 0.1 2.0)))  ; conditional

The interactive spec and documentation of FUNC is carried over to the new
function.
