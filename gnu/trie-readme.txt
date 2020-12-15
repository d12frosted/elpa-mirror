Quick Overview
--------------
A trie is a data structure used to store keys that are ordered sequences of
elements (vectors, lists, or strings in Elisp; strings are by far the most
common), in such a way that both storage and retrieval are space- and
time-efficient. But, more importantly, a variety of more advanced queries
can also be performed efficiently: for example, returning all strings with
a given prefix, searching for keys matching a given wildcard pattern or
regular expression, or searching for all keys that match any of the above
to within a given Lewenstein distance.

You create a trie using `make-trie', create an association using
`trie-insert', retrieve an association using `trie-lookup', and map over a
trie using `trie-map', `trie-mapc', `trie-mapcar', or `trie-mapf'. You can
find completions of a prefix sequence using `trie-complete', search for
keys matching a regular expression using `trie-regexp-search', find fuzzy
matches within a given Lewenstein distance (edit distance) of a string
using `trie-fuzzy-match', and find completions of prefixes within a given
distance using `trie-fuzzy-complete'.

Using `trie-stack', you can create an object that allows the contents of
the trie to be used like a stack, useful for building other algorithms on
top of tries; `trie-stack-pop' pops elements off the stack one-by-one, in
"lexicographic" order, whilst `trie-stack-push' pushes things onto the
stack. Similarly, `trie-complete-stack', `trie-regexp-stack',
`trie-fuzzy-match-stack' and `trie-fuzzy-complete-stack' create
"lexicographicly-ordered" stacks of query results.

Very similar to trie-stacks, `trie-iter', `trie-complete-iter',
`trie-regexp-iter', `trie-fuzzy-match-iter' and `trie-fuzzy-complete-iter'
generate iterator objects, which can be used to retrieve successive
elements by calling `iter-next' on them.

Note that there are two uses for a trie: as a lookup table, in which case
only the presence or absence of a key in the trie is significant, or as an
associative array, in which case each key carries some associated
data. Libraries for other data structure often only implement lookup
tables, leaving it up to you to implement an associative array on top of
this (by storing key+data pairs in the data structure's keys, then defining
a comparison function that only compares the key part). For a trie,
however, the underlying data structures naturally support associative
arrays at no extra cost, so this package does the opposite: it implements
associative arrays, and leaves it up to you to use them as lookup tables if
you so desire, by ignoring the associated data.


Different Types of Trie
-----------------------
There are numerous ways to implement trie data structures internally, each
with its own time- and space-efficiency trade-offs. By viewing a trie as a
tree whose nodes are themselves lookup tables for key elements, this
package is able to support all types of trie in a uniform manner. This
relies on there existing (or you writing!) an Elisp implementation of the
corresponding type of lookup table. The best type of trie to use will
depend on what trade-offs are appropriate for your particular
application. The following gives an overview of the advantages and
disadvantages of various types of trie. (Not all of the underlying lookup
tables have been implemented in Elisp yet, so using some of the trie types
described below would require writing the missing Elisp package!)


One of the most effective all-round implementations of a trie is a ternary
search tree, which can be viewed as a tree of binary trees. If basic binary
search trees are used for the nodes of the trie, we get a standard ternary
search tree. If self-balancing binary trees are used (e.g. AVL or red-black
trees), we get a self-balancing ternary search tree. If splay trees are
used, we get yet another self-organising variant of a ternary search
tree. All ternary search trees have, in common, good space-efficiency. The
time-efficiency of the various trie operations is also good, assuming the
underlying binary trees are balanced. Under that assumption, all variants
of ternary search trees described below have the same asymptotic
time-complexity for all trie operations.

Self-balancing trees ensure the underlying binary trees are always close to
perfectly balanced, with the usual trade-offs between the different the
types of self-balancing binary tree: AVL trees are slightly more efficient
for lookup operations than red-black trees, at a cost of slightly less
efficienct insertion operations, and less efficient deletion
operations. Splay trees give good average-case complexity and are simpler
to implement than AVL or red-black trees (which can mean they're faster in
practice), at the expense of poor worst-case complexity.

If your tries are going to be static (i.e. created once and rarely
modified), then using perfectly balanced binary search trees might be
appropriate. Perfectly balancing the binary trees is very inefficient, but
it only has to be done when the trie is first created or modified. Lookup
operations will then be as efficient as possible for ternary search trees,
and the implementation will also be simpler (so probably faster) than a
self-balancing tree, without the space and time overhead required to keep
track of rebalancing.

On the other hand, adding data to a binary search tree in a random order
usually results in a reasonably balanced tree. If this is the likely
scenario, using a basic binary tree without bothering to balance it at all
might be quite efficient, and, being even simpler to implement, could be
quite fast overall.


A digital trie is a different implementation of a trie, which can be viewed
as a tree of arrays, and has different space- and time-complexities than a
ternary search tree. Roughly speaking, a digital trie has worse
space-complexity, but better time-complexity. Using hash tables instead of
arrays for the nodes gives something similar to a digital trie, potentially
with better space-complexity and the same amortised time-complexity, but at
the expense of occasional significant inefficiency when inserting and
deleting (whenever a hash table has to be resized). Indeed, an array can be
viewed as a perfect hash table, but as such it requires the number of
possible values to be known in advance.

Finally, if you really need optimal efficiency from your trie, you could
even write a custom type of underlying lookup table, optimised for your
specific needs.

This package uses the AVL tree package avl-tree.el, the tagged NFA package
tNFA.el, and the heap package heap.el.