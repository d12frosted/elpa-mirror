This program insert terminology from top Google search results.
It requires w3m (http://w3m.sourceforge.net/).
It also requires two emacs packages from https://melpa.org/,
 - w3m (http://melpa.org/#/w3m)
 - ivy (http://melpa.org/#/ivy)

Usage,
`M-x fastdef-insert' to insert terminology from Google.
`M-x fastdef-insert-from-history' to re-use previous results.

`fastdef-text-template' decides the format of inserted content.

Change `fastdef-search-engine' and `fastdef-regexp-extract-url'
to switch search engine.
