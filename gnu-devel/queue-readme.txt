These queues can be used both as a first-in last-out (FILO) and as a
first-in first-out (FIFO) stack, i.e. elements can be added to the front or
back of the queue, and can be removed from the front. (This type of data
structure is sometimes called an "output-restricted deque".)

You create a queue using `make-queue', add an element to the end of the
queue using `queue-enqueue', and push an element onto the front of the
queue using `queue-prepend'. To remove the first element from a queue, use
`queue-dequeue'. A number of other queue convenience functions are also
provided, all starting with the prefix `queue-'.  Functions with prefix
`queue--' are for internal use only, and should never be used outside this
package.