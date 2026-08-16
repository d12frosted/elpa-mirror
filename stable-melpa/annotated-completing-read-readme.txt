Provides `annotated-completing-read', a wrapper around
`completing-read', that accepts a hash table of candidates to
annotations and surfaces them as aligned completion metadata
understood by vertico, marginalia, and embark.

Also provides `annotated-completing-read-context-from-point', a
context-aware selection interface, that populates candidates from
thing-at-point, the active region, the current line, and the kill
ring.
