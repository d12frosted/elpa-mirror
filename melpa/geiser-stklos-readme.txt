
Geiser, STklos and Geisr-STklos
───────────────────────────────

Geiser (https://www.nongnu.org/geiser/) is a collection of Emacs
major and minor modes for Scheme development.

STklos (http://stklos.net) is a free Scheme system mostly compliant
with the languages features defined in R7RS small.  The aim of this
implementation is to be fast as well as light.  The implementation is
based on an ad-hoc Virtual Machine.  STklos can also be compiled as a
library and embedded in an application.

Geiser-Stklos adds STklos Scheme support to the Geiser package.

Supported Geiser features
─────────────────────────

* evaluation of sexps, definitions, regions and whole buffers
* loading Scheme files
* adding paths to `load-path`
* macroexpansion
* symbol completion
* listing of module exported symbols
* autodoc (signature of procedurs and values of symbols are displayed in the minibuffer
  when the mouse hovers over their names)
* symbol documentation (docstrings for procedures, and values of variables)

Unsupported Geiser features
───────────────────────────

* finding the definition of a symbol (no support in STklos)
* seeing callees and callers of a procedure (no support in STklos)
* looking up symbols in the manual (would need to download the index from the STklos
  manual and parse the DOM of its index; a bit too much, maybe someday...)

Usage
─────

Please consult the Geiser manual at https://www.nongnu.org/geiser/

Notes
─────

* Squarify (alternating between "[" and "(" ) only works when the cursor is inside a form

Bugs
────

See the Gitlab issue tracker at https://gitlab.com/emacs-geiser/stklos/-/issues



