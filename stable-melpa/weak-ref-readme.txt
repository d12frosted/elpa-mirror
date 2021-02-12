The Emacs Lisp environment supports weak references, but only for
hash table keys and values. This can be exploited to generalize
weak references into two convenient macros:

  * `weak-ref'   : create a weak reference to an object
  * `weak-ref-deref' : access the object behind a weak reference

The weakness can be demonstrated like so:

    (setq ref (weak-ref (list 1 2 3)))
    (weak-ref-deref ref) ; => (1 2 3)
    (garbage-collect)
    (weak-ref-deref ref) ; => nil

See also: https://github.com/melpa/melpa/pull/6670
