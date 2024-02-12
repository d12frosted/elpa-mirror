
Transducers are an ergonomic and extremely memory-efficient way to process a
data source. Here "data source" means simple collections like Lists or
Vectors, but also potentially large files or generators of infinite data.

Transducers...

- allow the chaining of operations like map and filter without allocating
  memory between each step.
- aren't tied to any specific data type; they need only be implemented once.
- vastly simplify "data transformation code".
- have nothing to do with "lazy evaluation".
- are a joy to use!

See the README for examples.

**Usage Note**

This library uses the `read-symbol-shorthands' feature introduced in Emacs
28. While browsing the code it may appear as if most of the functions are
prefixed by `t-', but in fact the symbols are exported with the full prefix
`transducers-'. Every user is then free to abbreviate the function symbols as
they wish in their own files, just like import systems in other languages
allow.

To enable this abbreviation in your own Emacs Lisp files, interactively call
`add-file-local-variable' and set `read-symbol-shorthands' to a value like
(("t-" . "transducers-")). You can see an example of this at the bottom of
this file (transducers.el).
