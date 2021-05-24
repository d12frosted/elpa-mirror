Symex mode (pronounced sym-ex, as in symbolic expression) is a vim-
inspired way of editing Lisp code as trees.  Entering symex mode
allows you to reason about your code in terms of its structure,
similar to other tools like paredit and lispy.  But while in those
packages the tree representation is implicit, symex mode models
the tree structure explicitly so that tree navigations and operations
can be described using an expressive DSL, and invoked in a vim-
style modal interface implemented with a Hydra.

At the moment, symex mode uses paredit, lispy, and evil-cleverparens
to provide much of its low level functionality.
In the future, this layer of primitives may be replaced with a layer
that explicitly uses the abstract syntax tree, for greater precision.
