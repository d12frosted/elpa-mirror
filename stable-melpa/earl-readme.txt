This library implements the Erlang distribution protocol as
described in
https://www.erlang.org/doc/apps/erts/erl_dist_protocol.html,
allowing Emacs to communicate with Erlang VMs as if it were another
Erlang node. This is achieved with an Erlang-like process runtime.

New processes are created by providing `earl-spawn' with a
generator function (see the `generator' package) to run. Scheduling
is cooperative, not preemptive---processes must voluntarily give
other processes the opportunity to run by calling `earl-yield' or
`earl-receive'. Inter-process communication happens solely through
asynchronous message passing. The following example (where "!" is a
shorthand for `earl-send') illustrates spawning a process that
replies once with the number it received plus one:

    (let ((pid (earl-spawn
                (iter-make (earl-receive
                            (`(,from . ,i) (! from (1+ i))))))))
      (! pid (cons (earl-self) 5))
      (earl-receive (i (message "Received %d!" i))))

Erlang terms in external term format, see
https://www.erlang.org/doc/apps/erts/erl_ext_dist.html, are
convertible to and from Emacs Lisp terms using the functions
`earl-read' and `earl-write', as per the table below:

    Erlang   <=>   Emacs Lisp
    ---------------------------------
    [] / [a | b]   nil / (a . b)
    nil            [EXT nil]
    {a, b}         [a b]
    #{...}         #s(hash-table ...)
    "foo"          (?f ?o ?o)
    <<"foo">>      "foo"

where "EXT" denotes the value of `earl-tag'. In addition, integers;
floats; and other atoms/symbols are converted to their respective
counterparts, and Erlang process identifiers and references are
translated to opaque ELisp objects. Bitstrings and ports are not
yet supported.

If a local Erlang VM was started with e.g. "erl -sname arnie", you
may connect to it and perform an RPC using:

    (earl-do (earl-call (earl-rpc (intern (concat "arnie@" (system-name)))
                                  'erlang 'node ())))
