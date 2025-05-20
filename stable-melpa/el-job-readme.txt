Imagine you have a function you'd like to run on a long list of inputs.
You could run (mapcar #'FN INPUTS), but that hangs Emacs until done.

This library lets you split up the inputs and run the function in many
subprocesses---one per CPU core---then merge their outputs and handle the
result as if it had been returned by that `mapcar'.  In the meantime,
current Emacs does not hang at all.

You do need to grok the concept of a callback.

Public API:
- Function `el-job-launch' (main entry point)
- Function `el-job-await'
- Function `el-job-is-busy'
- Variable `el-job-major-version'

Dev tools:
- Command `el-job-cycle-debug-level'
- Command `el-job-show-info'
- Command `el-job-kill-all'
