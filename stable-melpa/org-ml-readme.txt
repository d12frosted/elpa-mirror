This is a functional API for org-mode primarily using the `org-element'
library. `org-element.el' provides the means for converting an org buffer to
a parse-tree data structure. This library contains functions to modify this
parse-tree in a more-or-less 'purely' functional manner (with the exception
of parsing from the buffer and writing back to the buffer). For the purpose
of this package, the resulting parse tree is composed of 'nodes'.

This library exposes the following types of functions:
- builder: build new nodes to be inserted into a parse tree
- property functions: return either property values (get) or nodes with
  modified properties (set and map)
- children functions: return either children of nodes (get) or return a node
  with modified children (set and map)
- node predicates: return t if node meets a condition
- pattern matching: return nodes based on a pattern that matches the parse
  tree (and perform operations on those nodes depending on the function)
- parsers: parse a buffer (optionally at current point) and return a parse
  tree
- writers: insert/update the contents of a buffer given a parse tree

For examples please see full documentation at:
https://github.com/ndwarshuis/org-ml
