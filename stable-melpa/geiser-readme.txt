Geiser is a generic Emacs/Scheme interaction mode, featuring an
enhanced REPL and a set of minor modes improving Emacs' basic scheme
major mode.

Geiser supports Guile, Chicken, Gauche, Chibi, MIT-Scheme, Gambit,
Racket, Stklos, Kawa and Chez.  Each one has a separate ELPA package
(geiser-guile, geiser-chicken, etc.) that you should install to use
your favourite scheme.


Main functionalities:
    - Evaluation of forms in the namespace of the current module.
    - Macro expansion.
    - File/module loading.
    - Namespace-aware identifier completion (including local bindings,
      names visible in the current module, and module names).
    - Autodoc: the echo area shows information about the signature of
      the procedure/macro around point automatically.
    - Jump to definition of identifier at point.
    - Direct access to documentation, including docstrings (when the
      implementation provides them) and user manuals.
    - Listings of identifiers exported by a given module (Guile).
    - Listings of callers/callees of procedures (Guile).
    - Rudimentary support for debugging (list of
      evaluation/compilation error in an Emacs' compilation-mode
      buffer).
    - Support for inline images in schemes, such as Racket, that treat
      them as first order values.

See http://www.nongnu.org/geiser/ for the full manual in HTML form, or
the the info manual installed by this package.
