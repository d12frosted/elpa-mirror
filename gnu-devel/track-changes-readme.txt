This library is a layer of abstraction above `before-change-functions'
and `after-change-functions' which takes care of accumulating changes
until a time when its client finds it convenient to react to them.

It provides an API that is easier to use correctly than our
`*-change-functions' hooks.  Problems that it claims to solve:

- Before and after calls are not necessarily paired.
- The beg/end values don't always match.
- There's usually only one call to the hooks per command but
  there can be thousands of calls from within a single command,
  so naive users will tend to write code that performs poorly
  in those rare cases.
- The hooks are run at a fairly low-level so there are things they
  really shouldn't do, such as modify the buffer or wait.
- The after call doesn't get enough info to rebuild the before-change state,
  so some callers need to use both before-c-f and after-c-f (and then
  deal with the first two points above).

The new API is almost like `after-change-functions' except that:
- It provides the "before string" (i.e. the previous content of
  the changed area) rather than only its length.
- It can combine several changes into larger ones.
- Clients do not have to process changes right away, instead they
  can let changes accumulate (by combining them into a larger change)
  until it is convenient for them to process them.
- By default, changes are signaled at most once per command.

The API consists in the following functions:

    (track-changes-register SIGNAL &key NOBEFORE DISJOINT IMMEDIATE)
    (track-changes-fetch ID FUNC)
    (track-changes-unregister ID)

A typical use case might look like:

    (defvar my-foo--change-tracker nil)
    (define-minor-mode my-foo-mode
      "Fooing like there's no tomorrow."
      (if (null my-foo-mode)
          (when my-foo--change-tracker
            (track-changes-unregister my-foo--change-tracker)
            (setq my-foo--change-tracker nil))
        (unless my-foo--change-tracker
          (setq my-foo--change-tracker
                (track-changes-register
                 (lambda (id)
                   (track-changes-fetch
                    id (lambda (beg end before)
                         ..DO THE THING..))))))))