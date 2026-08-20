A fast, Magit-inspired interface for the Sapling SCM (`sl').

The status buffer is the main entry point:

  M-x sapling-status

It intentionally uses the same command names as Sapling where possible
(`commit', `amend', `absorb', `rebase', `shelve', `smartlog', ...).

The separate `vc-sapling' package adds a Sapling backend for Emacs's
generic VC commands (`C-x v =', `C-x v d', `C-x v l', ...).

On Windows the package avoids shell wrappers whenever possible, runs `sl'
through `make-process' with pipe connections, forces UTF-8 decoding, and
lowers `w32-pipe-read-delay' for faster output processing.