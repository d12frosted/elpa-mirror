Provides a global minor mode that changes how Emacs handles the
lookup of applicable dir-locals files (".dir-locals.el"): instead of
starting at the directory of the visited file and moving up the
directory tree only until a first dir-locals file is found, collect
and apply all (!) dir-locals files found from the current directory
up to the root one.

Values specified in files nearer to the current directory take
precedence over values in files farther away from it.

You might want to use this to globally set dir-local variables that
apply to all of your projects, then override or add variables on a
per-project basis.
