This library provides an implementation of streams. Streams are
implemented as delayed evaluation of cons cells.

Functions defined in `seq.el' can also take a stream as input.

streams could be created from any sequential input data:
- sequences, making operation on them lazy
- a set of 2 forms (first and rest), making it easy to represent infinite sequences
- buffers (by character)
- buffers (by line)
- buffers (by page)
- IO streams
- orgmode table cells
- ...

All functions are prefixed with "stream-".
All functions are tested in tests/stream-tests.el

Here is an example implementation of the Fibonacci numbers
implemented as in infinite stream:

(defun fib (a b)
 (stream-cons a (fib b (+ a b))))
(fib 0 1)

A note for developers: Please make sure to implement functions that
process streams (build new streams out of given streams) in a way
that no new elements in any argument stream are generated.  This is
most likely an error since it changes the argument stream.  For
example, a common error is to call `stream-empty-p' on an input
stream and build the stream to return depending on the result.
Instead, delay such tests until elements are requested from the
resulting stream.  A way to achieve this is to wrap such tests into
`stream-make' or `stream-delay'.  See the implementations of
`stream-append' or `seq-drop-while' for example.