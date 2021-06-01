`loopy' is a macro that is used similarly to `cl-loop'.  It provides "loop
commands" that define a loop body and it's surrounding environment, as well
as exit conditions.

There are several special macro arguments:

  - `with' declares variables that are bound in order before and around the
    loop, like in a `let*' binding.

  - `without' declares variables that ~loopy~ should not try to initialize.

  - `before-do' is a list of normal Lisp expressions to run before the loop
    executes.

  - `after-do' is a list of normal Lisp expressions to run after the successful
    completion of the loop.

  - `finally-do' is a list of normal Lisp expressions that always run,
    regardless of whether an early return was triggered in the loop body.

  - `finally-return' is an expression whose value is always returned, regardless
    of whether an early return was triggered in the loop body.

  - `flags' is a list of symbols that change the macro's behavior.

Additionally, a symbol can be used to name the loop.

Any argument that doesn't match the above is taken to be a loop command.  The
loop commands generally follow the form `(COMMAND VARIABLE-NAME &rest ARGS)'.
For example,

- To iterate through a sequence, use `(seq elem [1 2 3])' (for
  efficiency, there are also more specific commands, like `list').
- To collect values into a list, use `(collect my-collection collected-value)'.
- To just bind a variable to the result of a Lisp expression, use
  `(expr my-var (my-func))'

For more information, including the full list of loop commands and how to
extend the macro, see this package's Info documentation under Info node
`(loopy)'.
