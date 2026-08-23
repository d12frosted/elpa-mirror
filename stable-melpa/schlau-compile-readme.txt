schlau-compile ("schlau" is German for "smart") is a `compile'
front end derived from `smart-compile', diverging from it in three
ways:

- Git-root awareness: the %G format sequence expands to the root
  of the current Git project, so compile commands can `cd' there
  before running, regardless of which file in the tree is current.
- `schlau-compile-compile' (recompile with the last-used command)
  and `schlau-compile-query' (prompt to edit the command first) are
  exposed as separate entry points, rather than one command with a
  prefix-argument toggle.
- `schlau-compile-alist' entries may associate a major mode or
  filename pattern with either a command template string or an
  arbitrary Lisp form to evaluate, as in the original, but this
  fork's alist is meant to be composed by downstream config (e.g.
  per-language `defconst' command templates) rather than edited
  in place.

Because of this divergence, and to keep clear which contributions
are whose, this is maintained as an independent package rather than
a pull request against `smart-compile'.

To use this package, add to your init file:
    (require 'schlau-compile)

See README.org in the repository for full documentation and
configuration examples.
