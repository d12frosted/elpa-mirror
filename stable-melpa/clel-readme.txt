The runtime library of ClojureElisp, a compiler from Clojure syntax
(.cljel files) to Emacs Lisp.  Compiled code calls these functions for
what Clojure has and Emacs Lisp lacks: Clojure's collection functions
over lists, vectors, alists and hash tables, lazy sequences, atoms,
transducers, protocols and multimethods, and the clojure.string and
clojure.set functions.

You do not call it directly.  A package compiled with ClojureElisp
lists clel in its Package-Requires, and each of its files requires
clel and refuses to load when `clel-runtime-version' is older than
the compiler that produced it expects.

This file is generated from runtime.cljel in the ClojureElisp
repository: edit that, not this file.
