Composable editing for Emacs

composable.el is composable text editing for Emacs.  It improves the
basic editing power of Emacs by making commands combineable.

It's inspired by vim but implemented in a way that reuses existing
Emacs infrastructure.  This makes it simple and compatible with
existing Emacs functionality and concepts.  composable.el only brings
together existing features in a slightly different way.

Composable editing is a simple abstraction that makes it possible to
combine _actions_ with _objects_.  The key insight in composable.el is
that Emacs already provides all the primitives to implement composable
editing.  An action is an Emacs command that operates on the region.
Thus `kill-region` and `comment-region` are actions.  An object is
specified by a command that moves point and optionally sets the mark
as well.  Examples are `move-end-of-line` and `mark-paragraph`.

So actions and objects are just names for things already present in
Emacs.  The primary feature that composable.el introduces is a
_composable command_.  A composable command has an associated action.
Invoking it works like this:

1. If the region is active the associated action is invoked directly.
2. Otherwise nothing happens, but the editor is now listening for an
   object.  This activates a set of bindings that makes it convenient
   to input objects.  For instance pressing `l` makes the action
   operate on the current line.
3. After the object has been entered the action is invoked on the
   specified object.
