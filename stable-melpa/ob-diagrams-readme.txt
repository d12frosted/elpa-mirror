Org-Babel support for evaluating diagrams source code.

This differs from most standard languages in that

1) we are generally only going to return results of type "file"

2) we are adding the "file" and "cmdline" header arguments

; Requirements:

- diagrams          :: http://projects.haskell.org/diagrams/
- diagrams-builder  :: http://hackage.haskell.org/package/diagrams-builder
