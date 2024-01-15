
See documentation for `ert-select-tests' for test SELECTOR types.

Within an interactive Emacs session, if `ert' is called with a
regular expression selector argument that matches to multiple test
names, all such tests are run, but only a summary line of output is
displayed for all passing tests.  Thus, the names of the passing
matched tests are not displayed.  Presently, within the *ert* output
buffer, you must press {j} on each individual test summary result to
display and jump to the test name and have its status spelled out,
rather than abbreviated.  This library fixes these problems and
extends the ert library with a number of useful commands.

The first command, `ert-results-toggle', is bound to {t} within the
ERT results buffer.  With each press, it toggles between showing and
hiding all test results.  After hiding the results, point is left on
the summary item associated with the test that had been at point, if
any.

The second command, `ert-results-filter', is bound to {f} within
the ERT results buffer.  It filters the results to just those entries
whose status matches that of the current entry.  Point may be on a
results entry or on a result character in the results summary.

With point on any of the statistics lines in the top section of the
results buffer, {f} does the following:
  Selector: - toggles showing/hiding all test results
  Passed:   - show passed tests only
  Failed:   - show failed tests only
  Skipped:  - show skipped tests only
  Total:    - show all tests

The third command, `ert-results-edebug', is bound to {e} within the
ERT results buffer, but also can be invoked by name within any ert
test definition in any buffer.  It instruments the current version of
the given test for electric debugging (edebugging) and then steps
through it in the test source buffer with edebug.

The fourth command, `ert-results-run', is not bound to a key.  It
works just like `ert-results-edebug' but instead of edebugging, it
simply runs the current version of the test.  You can bind it
yourself to {r} to replace ert's `ert-results-rerun-test-at-point'
command if you prefer a single command that you can use in both the
results buffer and test definitions.

All key bindings for this library are made only if the "ert" library
or the user has not already bound them in `ert-results-mode'.

------------

This library also provides the following commands for the results buffer:
  `ert-results-hide'     - hide all test results
  `ert-results-show'     - show all test results
  `ert-results-display'  - show all test results; with prefix arg, hide

This library also provides these functions that map over all tests
in the results buffer:
  `ert-results-all-test-bodies' - get a list of test bodies in the buffer
  `ert-results-all-test-names'  - get a list of test names in the buffer
  `ert-results-all-test-tags'   - get a list of test tags in the buffer

------------

To use:

  Simply load some ERT tests, load this library, interactively run `ert'
  with a regular expression or string matching to some test names, wait
  for ERT to output its summary line in the results buffer and then
  press {t} to see all of the tests that were run together with their
  final status and any errors.  Press {t} again to hide all this detail.
  Press {f} to filter entries to the current context and {e} to edebug
  a test at point.
