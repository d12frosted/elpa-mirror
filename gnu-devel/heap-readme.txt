A heap is a form of efficient self-sorting tree. In particular, the root
node is guaranteed to be the highest-ranked entry in the tree. (The
comparison function used for ranking the data can, of course, be freely
defined). Therefore repeatedly removing the root node will return the data
in order of increasing rank. They are often used as priority queues, for
scheduling tasks in order of importance.

This package implements ternary heaps, since they are about 12% more
efficient than binary heaps for heaps containing more than about 10
elements, and for very small heaps the difference is negligible. The
asymptotic complexity of ternary heap operations is the same as for a
binary heap: 'add', 'delete-root' and 'modify' operations are all O(log n)
on a heap containing n elements.

Note that this package implements a heap as an implicit data structure on a
vector. Therefore, the maximum size of the heap has to be specified in
advance. Although the heap will grow dynamically if it becomes full, this
requires copying the entire heap, so insertion has worst-case complexity
O(n) instead of O(log n), though the amortized complexity is still
O(log n). (For applications where the maximum size of the heap is not known
in advance, an implementation based on binary trees might be more suitable,
but is not currently implemented in this package.)

You create a heap using `make-heap', add elements to it using `heap-add',
delete and return the root of the heap using `heap-delete-root', and modify
an element of the heap using `heap-modify'. A number of other heap
convenience functions are also provided, all with the prefix
`heap-'. Functions with prefix `heap--' are for internal use only, and
should never be used outside this package.