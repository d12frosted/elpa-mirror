A path-iterator object is created by `make-path-iterator', which
takes keyword arguments:

user-path-non-recursive: list of directories to return, in order given

user-path-recursive: list of root directory trees to return; trees
are explored in depth-first order, after all directories in
`user-path-non-recursive' are returned.

ignore-function: a function that takes one argument (an absolute
directory name), and returns nil if directory should be returned,
non-nil if not.

Other functions:

path-iter-next: return the next directory, or nil if done.

path-iter-restart: restart iterator; next call to `path-iter-next'
will return the first directory.

path-iter-reset: clear internal caches; recompute the path. In
normal operation, the directories returned from both the
non-recursive and recursive path are cached in an array in the
first iteration, and subsequent iterations just return items in
that array. This avoids calling `directory-files' and the
ignore-function on iterations after the first. `path-iter-reset'
should be called if directories are added/deleted in the recursive
path, or if the ignore-function is changed,

path-iter-contains-root: non-nil if the iterator directory lists
contain the given directory. For both the non-recursive and
recursive lists, the given directory must be in the list; nested
directories return nil.

path-iter-expand-filename: expand a given filename against all the
directories returned by the iterator, return the first one that
exists, or nil if the filename exists in none of the directories.