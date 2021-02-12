Print buttercup test results to JUnit XML report files, while also
producing normal buttercup output on stdout.

`emacs -batch -L . -f package-initialize -f buttercup-junit-run-discover [buttercup-options]'

buttercup-junit-run-discover can be configured with the following
command line options:

 --xmlfile FILE    Write JUnit report to FILE
 --junit-stdout    Write JUnit report to stdout.
                   The report file will also be written to stdout,
                   after the normal buttercup report.
 --outer-suite     Add a wrapping testsuite around the outer suites.

buttercup tests are grouped into descriptions, and descriptions can
be contained in other descriptions creating a tree structure where
the tests are leafs.  buttercup-junit will output a testsuite for
each buttercup description and a testcase for each `it' testcase.
Pending tests will be marked as skipped in the report.
