In use for testing the Emacs Lisp implementation performance.

To minimize CPU frequency bouncing effects and other sources of
noise all benchmarks are repeated `elb-runs' times by default.

To add a new benchmark just depose the file into the benchmarks/
directory.  Every benchmark foo.el has to define as entry-point a
function `elb-FOO-entry'.

Entry points can choose one of two calling conventions:

- Take no argument (and the result value is ignored).
  In this case the benchmark just measures the time it takes to run
  that function.
- Take one argument MEASURING-FUNCTION: in that case, the
  entry point needs to call MEASURING-FUNCTION: once with
  a function (of no argument) as argument and it should return
  the value returned by MEASURING-FUNCTION.
  The benchmark measures the time it takes to run that function
  of no arguments.
  This calling convention is used when the benchmark needs to set things
  up before running the actual code that needs to be measured.

Tests are of an arbitrary length that on my machine is in the
order of magnitude of 10 seconds for each single run
byte-compiled.  Please consider this as relative measure when
adding new benchmarks.