ε-prolog (eprolog) is a complete Prolog engine implementation written
in pure Emacs Lisp.  It provides a fully functional Prolog system
integrated into the Emacs environment, offering traditional Prolog
programming capabilities with seamless Lisp interoperability.

Features:
- Complete unification algorithm with occurs check
- Backtracking and choice points with proper cut (!) semantics
- Clause database management for facts and rules
- Interactive query execution with solution enumeration
- Built-in predicates for type checking, control, and list operations
- Definite Clause Grammar (DCG) support
- Spy/debugging functionality for tracing execution
- Direct Lisp integration through special predicates

Quick Start:

  ;; Define facts and rules
  (eprolog-define-prolog-predicate parent (tom bob))
  (eprolog-define-prolog-predicate parent (bob ann))

  (eprolog-define-prolog-predicate grandparent (_x _z)
    (parent _x _y)
    (parent _y _z))

  ;; Query the database
  (eprolog-query (grandparent tom _x))

See README.org for detailed documentation.
