<img src="treepy.png" align="right" />

# treepy.el (*ˈtriːpi*)
[![MELPA](https://melpa.org/packages/treepy-badge.svg)](https://melpa.org/#/treepy)
[![Emacs](https://img.shields.io/badge/Emacs-25-8e44bd.svg)](https://www.gnu.org/software/emacs/)
[![Build Status](https://travis-ci.org/volrath/treepy.el.svg?branch=master)](https://travis-ci.org/volrath/treepy.el)

A set of generic functions for traversing tree-like data structures recursively
and/or iteratively, ported
from [`clojure.walk`](https://clojure.github.io/clojure/clojure.walk-api.html)
and [`clojure.zip`](http://clojure.github.io/clojure/clojure.zip-api.html)
respectively.

## Table of Contents

- [Getting Started](#getting-started)
- [Available Functions](#available-functions)
  - [Walker](#walker)
  - [Zipper](#zipper)
- [Main differences with Clojure libraries](#main-differences-with-clojure-libraries)
  - [clojure.walk](#clojure.walk)
  - [clojure.zip](#clojure.zip)
- [Prior Art](#prior-art)

## Getting Started

*treepy* supports `Emacs 25.1+`.

It is available in MELPA, which is the recommended way to install it and keep it
up to date.

To install it, you may do

```
M-x package-install RET treepy RET
```

If the installation doesn't work, consider refreshing the package list: `M-x
package-refresh-contents [RET]`

For a manual installation, just place `treepy.el` in your `load-path` and
`(require 'treepy)`. Then you'll have all the `treepy-*` functions available.

## Available functions

### Walker

- `treepy-walk` inner outer form

  Traverses FORM, an arbitrary data structure. INNER and OUTER are functions.
  Applies INNER to each element of FORM, building up a data structure of the
  same type, then applies OUTER to the result. Recognizes cons, lists, alists,
  vectors and hash tables.

- `treepy-postwalk` f form

  Performs a depth-first, post-order traversal of F applied to FORM. Calls F on
  each sub-form, uses F's return value in place of the original. Recognizes
  cons, lists, alists, vectors and hash tables.

- `treepy-prewalk` f form

  Like `treepy-postwalk`, Performs function F on FORM but does pre-order
  traversal.

- `treepy-prewalk-demo` form

  Demonstrates the behavior of `treepy-prewalk` for FORM. Returns a list of
  each form as it is walked.

- `treepy-postwalk-demo` form

  Demonstrates the behavior of `treepy-postwalk` for FORM. Returns a list of
  each form as it is walked.

- `treepy-postwalk-replace` smap form &optional testfn

  Recursively transforms FORM by replacing keys in SMAP with their values. Does
  replacement at the root of the tree first. The optional TESTFN is passed to
  `map-contains-key` as the testing equality function.

- `treepy-postwalk-replace` smap form &optional testfn

  Recursively transforms FORM by replacing keys in SMAP with their values. Does
  replacement at the leaves of the tree first. The optional TESTFN is passed to
  `map-contains-key` as the testing equality function.

### Zipper

#### Construction

- `treepy-zipper` branchp children make-node root

  Creates a new zipper structure.

  BRANCHP is a function that, given a node, returns t if it can have children,
  even if it currently doesn't.

  CHILDREN is a function that, given a branch node, returns a seq of its
  children.

  MAKE-NODE is a function that, given an existing node and a seq of children,
  returns a new branch node with the supplied children.

  ROOT is the root node.

- `treepy-list-zip` root

  Returns a zipper for nested lists, given a ROOT list.

- `treepy-vector-zip` root

  Returns a zipper for nested vectors, given a ROOT vector.

#### Context / Path

- `treepy-node` loc

  Returns the node at LOC.

- `treepy-branch-p` loc

  Returns `t` if the node at LOC is a branch. `nil` otherwise.

- `treepy-children` loc

  Returns a children list of the node at LOC, which must be a branch.

- `treepy-make-node` loc node children

  Returns a new branch node, given an existing LOC, NODE and new CHILDREN. The
  LOC is only used to supply the constructor.

- `treepy-path` loc

  Returns a list of nodes leading to the given LOC.

- `treepy-lefts` loc

  Returns a list of the left sibilings of this LOC.

- `treepy-rights` loc

  Returns a list of the right sibilings of this LOC.

#### Navigation

- `treepy-down` loc

  Returns the loc of the leftmost child of the node at this LOC, or `nil` if no
  children.

- `treepy-up` loc

  Returns the loc of the parent of the node at this LOC, or `nil` if at the top.

- `treepy-root` loc

  Zips from LOC all the way up and return the root node, reflecting any changes.

- `treepy-right` loc

  Returns the loc of the right sibling of the node at this LOC, or `nil`.

- `treepy-rightmost` loc

  Returns the loc of the rightmost sibling of the node at this LOC, or self.

- `treepy-left` loc

  Returns the loc of the left sibling of the node at this LOC, or `nil`.

- `treepy-leftmost` loc

  Returns the loc of the leftmost sibling of the node at this LOC, or self.

- `treepy-leftmost-descendant` loc

  Returns the leftmost descendant of the given LOC. (ie, down repeatedly).

#### Modification

- `treepy-insert-left` loc item

  Inserts ITEM as the left sibling of this LOC'S node, without moving.

- `treepy-insert-right` loc item

  Inserts ITEM as the right sibling of this LOC's node, without moving.

- `treepy-replace` loc node

  Replaces the node in this LOC with the given NODE, without moving.

- `treepy-edit` loc f &rest args

  Replaces the node at this LOC with the value of `(F node ARGS)`.

- `treepy-insert-child` loc item

  Inserts ITEM as the leftmost child of this LOC's node, without moving.

- `treepy-append-child` loc item

  Inserts ITEM as the rightmost child of this LOC'S node, without moving.

- `treepy-remove` loc

  Removes the node at LOC. Returns the loc that would have preceded it in a
  depth-first walk.

#### Enumeration

- `treepy-next` loc &optional order

  Moves to the next LOC in the hierarchy, depth-first, using ORDER if given.
  Possible values for ORDER are `:preorder` and `:postorder`, defaults to the
  former. When reaching the end, returns a distinguished loc detectable via
  `treepy-end-p`. If already at the end, stays there.

- `treepy-next` loc &optional order

  Moves to the previous LOC in the hierarchy, depth-first, using ORDER if given.
  Possible values for ORDER are `:preorder` and `:postorder`, defaults to the
  former.

- `treepy-end-p` loc

  Returns `t` if LOC represents the end of a depth-first walk, `nil` otherwise.

## Main differences with clojure libraries

Even though one of *treepy's* goals is to provide an API that's as close as
possible
to [`clojure.walk`](https://clojure.github.io/clojure/clojure.walk-api.html)
and [`clojure.zip`](http://clojure.github.io/clojure/clojure.zip-api.html),
there are some subtle (and not so subtle) differences derived from elisp/clojure
distinct data structures, levels of abstraction, and code conventions.

The most notorious difference is the name of the functions. For every function
in Clojure world, there's a *treepy* counterpart that's prefixed with `treepy-`.
So:

- `clojure.walk/walk` -> `treepy-walk`
- `clojure.zip/zipper` -> `treepy-zipper`

... and so on.

### clojure.walk

- `treepy-walk` (and all its derivatives) works on lists, vectors, alists and
  hash-tables only.

- Instead of printing to stdout, `treepy-prewalk-demo` and
  `treepy-postwalk-demo` return a list of the sub forms as they get walked.

- *treepy* doesn't provide implementations for `keywordize-keys`,
  `stringify-keys` and `macroexpand-all`. There's already
  a
  [`macroexpand-all` implementation built in](https://www.gnu.org/software/emacs/manual/html_node/elisp/Expansion.html).

- `treepy-prewalk-replace` and `treepy-postwalk-replace` are based on the (Emacs
  25) built
  in
  [`map-contains-key`](https://github.com/emacs-mirror/emacs/blob/master/lisp/emacs-lisp/map.el#L262) function.
  Both functions take an optional a *testfn* third parameter to be used by
  `map-contains-key`. Defaults to `equal`.

### clojure.zip

- In order to follow elisp conventions, *treepy* has a couple of other small
  renamings:

  * `clojure.zip/branch?` -> `treepy-branch-p`
  * `clojure.zip/end?` -> `treepy-end-p`

- There's is no exact equivalent to `clojure.zip/seq-zip` in *treepy*, a
  `treepy-list-zip` is provided instead.

- *treepy* provides a way to traverse a tree in postorder while using the
  enumeration functions `treepy-next` and `treepy-prev`. This is done by having
  an extra optional parameter *order* that can be passed to both functions:

```
(treepy-next loc)  ;; => next node in preorder, as in clojure.zip/next.
(treepy-next loc :preorder)  ;; => also next node in preorder.
(treepy-next loc :postorder)  ;; => next node in postorder.
```

- There's a new function in *treepy* to get the leftmost descendant of a
  node/loc. Unsurprisingly, it's called `treepy-leftmost-descendant`. This function
  is particularly useful when trying to traverse a tree in post order, since
  unlike preorder trasversal, the root is NOT the first element you want
  walk/visit. You might want to call `(treepy-leftmost-descendant root)` before
  starting to walk the nodes with `treepy-next` in postorder.

The following are some *treepy*'s implementation differences that you might not
need to bother with if you just wanna use the library.

- **treepy's *loc* data structure:** When you create a Clojure "zipper" with
  `clojure.zip/zipper`, you have to provide three helper functions (`branch?`,
  `children`, and `make-node`) and a `root` form. `clojure.zip/zipper` will then
  return a tuple vector that represents a "*loc*action". The three helper
  functions are stored as
  clojure's [metadata](https://clojure.org/reference/metadata) into the returned
  *loc*. Since there's no equivalent to metadata in Elisp, *treepy* directly
  associates the three helper functions into an alist that's returned with the
  rest of the *loc* information. The resulting structure of a *treepy* `loc` is
  the following:

```
((<current node> . <path alist>) . ((:branch-p . #'provided-branch-fn)
                                    (:children . #'provided-children-fn)
                                    (:make-node . #'provided-make-node-fn)))
```

- `<path alist>` is an alist containing the same keys and values as
  `clojure.zip`'s path map. Only difference is that *treepy* uses lists instead
  of vectors to handle the `left` sibilings and `pnodes` parent nodes.

## Prior Art

- [xiongtx/zipper.el](https://github.com/xiongtx/zipper.el): Non-generic, EIEIO,
  zipper implementation.

- [danielfm/cl-zipper](https://github.com/danielfm/cl-zipper): Common Lisp
  zipper implementation.

## LICENSE

&copy; 2017 Daniel Barreto

Distributed under the terms of the GNU GENERAL PUBLIC LICENSE, version 3.
