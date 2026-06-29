This package implements Eugene W. Myers's "stacks" which are like
standard singly-linked lists, except that they also provide efficient
lookup.  More specifically:

cons/car/cdr are O(1), while (nthcdr N L) is O(min (N, log L))

For details, see "An applicative random-access stack", Eugene W. Myers,
1983, Information Processing Letters
http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.188.9344&rep=rep1&type=pdf