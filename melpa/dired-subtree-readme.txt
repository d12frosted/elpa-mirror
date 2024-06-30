Introduction
------------

The basic command to work with subdirectories in dired is `i',
which inserts the subdirectory as a separate listing in the active
dired buffer.

This package defines function `dired-subtree-insert' which instead
inserts the subdirectory directly below its line in the original
listing, and indent the listing of subdirectory to resemble a
tree-like structure (somewhat similar to tree(1) except the pretty
graphics).  The tree display is somewhat more intuitive than the
default "flat" subdirectory manipulation provided by `i'.

There are several presentation options and faces you can customize
to change the way subtrees are displayed.

You can further remove the unwanted lines from the subtree by using
`k' command or some of the built-in "focusing" functions, such as
`dired-subtree-only-*' (see list below).

If you have the package `dired-filter', you can additionally filter
the subtrees with global or local filters.

A demo of basic functionality is available on youtube:
https://www.youtube.com/watch?v=z26b8HKFsNE

Interactive functions
---------------------

Here's a list of available interactive functions.  You can read
more about each one by using the built-in documentation facilities
of Emacs.  It is adviced to place bindings for these into a
convenient prefix key map, for example C-,

* `dired-subtree-insert'
* `dired-subtree-remove'
* `dired-subtree-toggle'
* `dired-subtree-cycle'
* `dired-subtree-revert'
* `dired-subtree-narrow'
* `dired-subtree-up'
* `dired-subtree-down'
* `dired-subtree-next-sibling'
* `dired-subtree-previous-sibling'
* `dired-subtree-beginning'
* `dired-subtree-end'
* `dired-subtree-mark-subtree'
* `dired-subtree-unmark-subtree'
* `dired-subtree-only-this-file'
* `dired-subtree-only-this-directory'

If you have package `dired-filter', additional command
`dired-subtree-apply-filter' is available.

See https://github.com/Fuco1/dired-hacks for the entire collection.
