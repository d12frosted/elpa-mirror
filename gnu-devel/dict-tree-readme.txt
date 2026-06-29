A dict-tree (created using `dictree-create') is used to store strings,
along with arbitrary data associated with each string. (Note that the
"strings" can be any sequence data type, not just Elisp strings.) As well
as basic data insertion (`dictree-insert'), manipulation
(`dictree-insert'), and retrieval (`dictree-lookup', `dictree-member-p'), a
dict-tree can perform sophisticated queries on strings, including:

- retrieve all completions of a prefix
  (`dictree-complete')

- retrieve all strings that match a regular expression
  (`dictree-regexp-search')

- retrieve all fuzzy matches to a string, i.e. matches within a specified
  Lewenstein distance (a.k.a. edit distance)
  (`dictree-fuzzy-match')

- retrieve all fuzzy completions of a prefix, i.e. completions of prefixes
  within a specified Lewenstein distance
  (`dictree-fuzzy-complete')

The results of all of these queries can be ranked in alphabetical order, or
according to any other desired ranking. The results can also be limited to
a given number of matches.

These sophisticated string queries are fast even for very large dict-trees,
and dict-tree's also cache query results (and automatically keep these
caches synchronised) to speed up queries even further.

Other functions allow you to:

- create dict-tree stack objects, which allow efficient access to the
  strings in the dictionary or in query results as though they were sorted
  on a stack (useful for designing efficient algorithms on top of
  dict-trees)
  (`dictree-stack', `dictree-complete-stack', `dictree-regexp-stack',
   `dictree-fuzzy-match-stack', `dictree-fuzzy-complete-stack')

- generate dict-tree iterator objects which allow you to retrieve
  successive elements by calling `iter-next'
  (`dictree-iter', `dictree-complete-iter', `dictree-regexp-iter',
   `dictree-fuzzy-match-iter', `dictree-fuzzy-complete-iter')

- map over all strings in alphabetical order
  (`dictree-mapc', `dictree-mapcar' and `dictree-mapf')

Dict-trees can be combined together into a "meta dict-tree", which combines
the data from identical keys in its constituent dict-trees, in whatever way
you specify (`dictree-create-meta-dict'). Any number of dict-trees can be
combined in this way. Meta-dicts behave *exactly* like dict-trees: all of
the above functions work on meta-dicts as well as dict-trees, and
meta-dicts can themselves be used in new meta-dicts.

The package also provides persistent storage of dict-trees to file.
(`dictree-save', `dictree-write', `dictee-load')

This package uses the trie package trie.el, the tagged NFA package tNFA.el,
and the heap package heap.el.