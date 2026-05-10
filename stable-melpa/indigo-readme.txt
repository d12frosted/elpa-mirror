This package provides Emacs Lisp bindings for the Indigo toolkit,
enabling molecular structure manipulation, chemical file I/O,
and cheminformatics operations from within Emacs.

The package is organized into modular components:
- Core module loading and resource management (indigo.el)
- Atom property functions and enums (indigo-atom.el)
- Bond property functions and enums (indigo-bond.el)
- Chemical object I/O and creation (indigo-io.el)
- Iterator functions (indigo-iterator.el)
- Lazy stream abstraction (indigo-stream.el)
- Molecule operations and search (indigo-mol.el)
- Reaction operations and mapping (indigo-reaction.el)
- Rendering and visualization (indigo-render.el)

The package provides both low-level stateful functions that work
directly with Indigo object handles, and high-level `indigo-with-*`
macros for automatic resource management (distributed across modules:
indigo-mol, indigo-io, indigo-iterator, indigo-render).
