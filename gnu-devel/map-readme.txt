map.el provides generic map-manipulation functions that work on
alists, plists, hash-tables, and arrays.  All functions are
prefixed with "map-".

Functions taking a predicate or iterating over a map using a
function take the function as their first argument.  All other
functions take the map as their first argument.

TODO:
- Add support for char-tables
- Maybe add support for gv?
- See if we can integrate text-properties
- A macro similar to let-alist but working on any type of map could
  be really useful