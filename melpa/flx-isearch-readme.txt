Fuzzy matching is awesome, when done right.

This program lets you isearch for "fiis" and be taken to matches for `flx-isearch-initialize-state'.
Searches currently only apply to symbols. The input string is flex matched to all symbols in the buffer,
and all matching symbols are searched one by one.

For example, searching for `fii` in `flx-isearch.el' first takes you to
* all instances of `flx-isearch-index' one by one
* all instances of `flx-isearch-initialize-state' one by one
* all instances of `flx-isearch-lazy-index' one by one
* [...]
* all instances of `bounds-of-thing-at-point' one by one

The _hope_ is that `flx' will be smart enough to quickly take you to the symbol you're thinking of with minimal effort.

Usage:

By default, `flx-isearch` does not bind any keys. `package.el' will
automatically setup the appropriate autoloads, and you can then do this:

    (global-set-key (kbd "C-M-s") #'flx-isearch-forward)
    (global-set-key (kbd "C-M-r") #'flx-isearch-backward)
