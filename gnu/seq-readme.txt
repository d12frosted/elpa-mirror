Sequence-manipulation functions that complement basic functions
provided by subr.el.

All functions are prefixed with "seq-".

All provided functions work on lists, strings and vectors.

Functions taking a predicate or iterating over a sequence using a
function as argument take the function as their first argument and
the sequence as their second argument.  All other functions take
the sequence as their first argument.

seq.el can be extended to support new type of sequences.  Here are
the generic functions that must be implemented by new seq types:
- `seq-elt'
- `seq-length'
- `seq-do'
- `seqp'
- `seq-subseq'
- `seq-into-sequence'
- `seq-copy'
- `seq-into'