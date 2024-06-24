timeout is a small elisp library that provides higher order functions to
throttle or debounce elisp functions.  This is useful for corraling
over-eager code that:
(i) is slow and blocks Emacs, and
(ii) does not provide customization options to limit how often it runs,

To throttle a function FUNC to run no more than once every 2 seconds, run
(timeout-throttle! func 2.0)

To debounce a function FUNC to run after a delay of 0.3 seconds, run
(timeout-debounce! func 0.3)
