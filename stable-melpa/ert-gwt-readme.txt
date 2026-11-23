ert-gwt adds Given-When-Then structure to ERT:

    (ert-gwt-deftest
      (:given ((user (make-user "alice" "secret"))))
      (:when  (login user))
      (:then  (login-redirects-to-home-p user)))

`:given' takes `let'-style bindings followed by setup forms and may
repeat; later givens see earlier bindings.  `:when' is the action
under test and is required.  `:then' forms are wrapped in `should'
and may repeat.  `:cleanup' forms run after the test, even on failure.

Each test is named after the defining file and a hash of its clauses
and file identity: <file-prefix>-<hash8>, with -2, -3, ... appended
when a file contains identical clauses more than once.  The name is
ERT's symbol; it is not written into the source, so the defining form
is recorded on the test symbol for `find-function'.

Setup stubs belong in `:given' as place bindings:

    (:given (((symbol-function 'yes-or-no-p)
               (lambda (_prompt) t))))

A `cl-letf' written as a setup form is not a stub: the rebinding is
undone as soon as that form finishes.

After the user `:cleanup' forms, buffers created during the test are
killed and files made with `ert-gwt--temp-file' are deleted.
