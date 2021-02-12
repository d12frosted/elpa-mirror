Buttercup is a behavior-driven development framework for testing
Emacs Lisp code. It is heavily inspired by the Jasmine test
framework for JavaScript.

A test suite begins with a call to the Buttercup macro `describe` with
the first parameter describing the suite and the rest being the body
of code that implements the suite.

(describe "A suite"
  (it "contains a spec with an expectation"
    (expect t :to-be t)))

The ideas for project were shamelessly taken from Jasmine
<https://jasmine.github.io>.

All the good ideas are theirs. All the problems are mine.
