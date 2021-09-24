This is a fuzzy Emacs completion style similar to the built-in
`flex' style, but with a better scoring algorithm. Specifically, it
is non-greedy and ranks completions that match at word; path
component; or camelCase boundaries higher.

To use this style, prepend `hotfuzz' to `completion-styles'.
