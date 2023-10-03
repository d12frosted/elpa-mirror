The `wrap-search' package offers non-incremental search.
It shows hitss (hits and only hits) and search only starts
when one hits RET.

`wrap-search' searches forward by default, but it wraps
and continues up and until the search start position if
necessary. This is so one doesn't have to wonder if the
target is north or south in the buffer.

The philosophy is that `wrap-search' mostly shouldn't be
used for searching - that is possible as well, of course,
using the same command - rather, it is used to quickly
navigate a buffer.

To use the package without keyboard shortcuts isn't
recommended. Instead, do for example

  (global-set-key "\C-s" #'wrap-search)
  (global-set-key "\C-r" #'wrap-search-again)