`memoize' accepts a symbol or a function. When given a symbol, the
symbol's function definition is memoized and installed overtop of
the original function definition. When given a function, it returns
a memoized version of that function.

    (memoize 'my-expensive-function)

`defmemoize' defines a memoized function directly, behaving just
like `defun'.

    (defmemoize my-expensive-function (x)
      (if (zerop n)
          1
        (* n (my-expensive-function (1- n)))))

Memoizing an interactive function will render that function
non-interactive. It would be easy to fix this problem when it comes
to non-byte-compiled functions, but recovering the interactive
definition from a byte-compiled function is more complex than I
care to deal with. Besides, interactive functions are always used
for their side effects anyway.

There's no way to memoize nil returns, but why would your expensive
functions do all that work just to return nil? :-)

Memoization takes up memory, which should be freed at some point.
Because of this, all memoization has a timeout from when the last
access was. The default timeout is set by
`memoize-default-timeout'.  It can be overriden by using the
`memoize' function, but the `defmemoize' macro will always just use
the default timeout.

If you wait to byte-compile the function until *after* it is
memoized then the function and memoization wrapper both get
compiled at once, so there's no special reason to do them
separately. But there really isn't much advantage to compiling the
memoization wrapper anyway.
