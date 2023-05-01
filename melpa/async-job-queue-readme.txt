Provide a queue for dispatching jobs asynchronously
while maintaining a fixed maximum number of active jobs

Lisp code can use this to create an arbitrary number of jobs
to be run asynchronously without immediately starting those
jobs.  The default number of jobs allowed to run simultaneously
is set to the number of processors reported by (num-processors)
when available, or 1 otherwise
