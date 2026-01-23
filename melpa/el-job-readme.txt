Imagine you have a function you'd like to run on a long list of inputs.
You could run (mapcar #'FN INPUTS), but that hangs Emacs until done.

This library lets you split up the inputs and run the function in many
subprocesses---one per CPU core---then merge their outputs and handle the
result as if it had been returned by that `mapcar'.  In the meantime,
current Emacs does not hang at all.

A high-level wrapper is `el-job-parallel-mapcar', which intentionally hangs
Emacs so as to behave as a drop-in for `mapcar' that is merely faster.

The more general `el-job-ng-run' can be used asynchronously.
