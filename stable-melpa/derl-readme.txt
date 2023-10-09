This library implements the Erlang distribution protocol as
described in
https://www.erlang.org/doc/apps/erts/erl_dist_protocol.html,
allowing Emacs to communicate with Erlang VMs as if it were another
Erlang node. This is achieved with an Erlang-like process runtime.

New processes are created by providing `derl-spawn' with a
generator function (see the `generator' package) to run. Scheduling
is cooperative, not preemptive---processes must voluntarily give
other processes the opportunity to run by calling `derl-yield' or
`derl-receive'. Inter-process communication happens solely through
asynchronous message passing. The following example (where "!" is a
shorthand for `derl-send') illustrates spawning a process that
replies once with the number it received plus one:

    (let ((pid (derl-spawn
                (iter-make (derl-receive
                            (`(,from . ,i) (! from (1+ i))))))))
      (! pid (cons (derl-self) 5))
      (derl-receive (i (message "Received %d!" i))))

Erlang terms in external term format, see
https://www.erlang.org/doc/apps/erts/erl_ext_dist.html, are
convertible to and from Emacs Lisp terms using the functions
`derl-read' and `derl-write', as per the table below:

    Erlang   <=>   Emacs Lisp
    ---------------------------------
    [] / [a | b]   nil / (a . b)
    nil            [EXT nil]
    {a, b}         [a b]
    #{...}         #s(hash-table ...)
    "foo"          (?f ?o ?o)
    <<"foo">>      "foo"

where "EXT" denotes the value of `derl-tag'. In addition, integers;
floats; and other atoms/symbols are converted to their respective
counterparts, and Erlang process identifiers and references are
translated to opaque ELisp objects. Bitstrings and ports are not
yet supported.

If a local Erlang VM was started with e.g. "erl -sname arnie", you
may connect to it and perform an RPC using:

    (derl-do (derl-call (derl-rpc (intern (concat "arnie@" (system-name)))
                                  'erlang 'node ())))
