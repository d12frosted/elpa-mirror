Mapping of symbols to constants that is stored externally as a
single binary file and loaded on-demand.  Can be used for huge
databases to avoid loading everything to memory.  This package
doesn't use any external programs, making it a suitable dependency
for smaller libraries.

Typical usage of the library consists of two separate stages:

    1) Package maintainer/developer creates a map file, which is
       then distributed along with its `*.el' etc. files.

    2) For end-user, Elisp code retrieves values from the
       pre-created map file.

Creating a map file doesn't require any external tools.  See
function `extmap-from-alist' for details.  If you use Emacs 25 or
later and your map is so huge that you don't want to load it fully
even when creating, see `extmap-from-iterator'.

The main functions for using an existing map file are `extmap-init'
to open it and `extmap-get' to retrieve value associated with given
key.  See function documentation for details.  Other functions that
work with a prepared file:

    - extmap-contains-key
    - extmap-value-loaded
    - extmap-keys
    - extmap-mapc
    - extmap-mapcar
    - extmap-statistics
