Self-balancing interval trees (for non-overlapping intervals, i.e.
similar to Emacs's text-properties (rather than overlays), but not
linked to any kind of buffer nor string).

Following Chris Okasaki's algorithm from
"Red-black trees in a functional setting", JFP'99.
https://dl.acm.org/citation.cfm?id=968578.968583&coll=DL&dl=GUIDE

The above article presents an elegant functional/persistent implementation
of insertion in red-black trees.  Here we have interval trees instead, so
it's a bit different and we support additional operations.  Those extensions
aren't nearly as well thought out as Chris's algorithm, so they actually
don't guarantee we preserve the 2 invariants of red-black trees :-(

In practice, they should still usually give reasonably good algorithmic
properties, hopefully.

For reference, the invariants are:
 1- a red node cannot have red children (local invariant).
 2- the left and right subtrees of a node must have the same black depth
    (global invariant).

When breaking invariants, we strive to only break invariant 1, since it can
be more easily recovered later via local runtime checks, whereas detecting
invariant 2 breakage requires a complete tree traversal.