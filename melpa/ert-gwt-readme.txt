ert-gwt adds Given-When-Then structure to ERT:

    (ert-gwt-deftest
      (:given ((user (make-user "alice" "secret"))))
      (:when  (login user))
      (:then  (login-redirects-to-home-p user)))

`:given' takes `let'-style bindings followed by setup forms and may
repeat; later givens see earlier bindings.  `:when' is the action
under test and is required.  `:then' forms are wrapped in `should'
and may repeat.  `:cleanup' forms run after the test, even on failure.

Each test is named after the defining file and a hash of its clauses:
<file-prefix>-<hash8>, with -2, -3, ... appended to repeated clauses.

Setup stubs belong in `:given'.  Since each given wraps the clauses
after it, a stub stays in effect through `:when' and `:then':

    (:given (cl-letf (((symbol-function 'yes-or-no-p)
                       (lambda (_prompt) t)))))

After the user `:cleanup' forms, buffers created during the test are
killed and files made with `ert-gwt--temp-file' are deleted.
