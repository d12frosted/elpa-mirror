This package adds Sapling (`sl') as a VC backend.  It intentionally
complements the separate `sapling' package rather than replacing it: the
Sapling-specific stack/smartlog interface lives in `sapling', while the
generic VC commands (`C-x v =', `C-x v d', `C-x v l', ...) are
served by this backend.

To enable it, install the `sapling' package, then add Sapling to
`vc-handled-backends':

  (add-to-list 'vc-handled-backends 'Sapling)

This backend recognizes native Sapling repositories (identified by
their `.sl' directory).  Git-backed Sapling working copies are
intentionally left to `vc-git', which is already a good fit for them.
Registration is deliberately conservative: if `sl' cannot be found,
or a file is not managed by Sapling, VC falls through to the next
backend.