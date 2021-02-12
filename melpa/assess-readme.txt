This file provides functions to support ert, the Emacs Regression Test
framework. It includes:

 - a set of predicates for comparing strings, buffers and file contents.
 - explainer functions for all predicates giving useful output
 - macros for creating many temporary buffers at once, and for restoring the
   buffer list.
 - methods for testing indentation, by comparison or "round-tripping".
 - methods for testing fontification.

Assess aims to be a stateless as possible, leaving Emacs unchanged whether
the tests succeed or fail, with respect to buffers, open files and so on; this
helps to keep tests independent from each other. Violations of this will be
considered a bug.

Assess aims also to be as noiseless as possible, reducing and suppressing
extraneous messages where possible, to leave a clean ert output in batch mode.
