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

  (keymap-global-set "C-s" #'wrap-search)
  (keymap-global-set "C-r" #'wrap-search-again)

One can use the `universal-argument' key, which is
typically C-u, before those functions to set two search
options before the search. If we assume the above keys are
used, then, for `wrap-search', here are the keys and what
they do,

        C-u C-s  do case-sensitive search
    C-u C-u C-s  do revere search, direction north from point
C-u C-u C-u C-s  do case-sensitive, reverse search

and for `wrap-search-again', using a corresponding interface

        C-u C-r  reverse previous search case-sensitive setting
    C-u C-u C-r  reverse previous search reverse setting
C-u C-u C-u C-r  reverse previous search case-sensitive and reverse settings

and the search is done again, with those settings.

See the docstrings for `wrap-search' and
`wrap-search-again'.