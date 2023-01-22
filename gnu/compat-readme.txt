To allow for the usage of Emacs functions and macros that are
defined in newer versions of Emacs, compat.el provides definitions
that are installed ONLY if necessary.  If Compat is installed on a
recent version of Emacs, all of the definitions are disabled at
compile time, such that no negative performance impact is incurred.
These reimplementations of functions and macros are at least
subsets of the actual implementations.  Be sure to read the
documentation string to make sure.

Not every function provided in newer versions of Emacs is provided
here.  Some depend on new features from the core, others cannot be
implemented to a meaningful degree.  Please consult the Compat
manual for details regarding the usage of the Compat library and
the provided functionality.  The main audience for this library are
not regular users, but package maintainers.  Therefore no commands,
user-facing modes or user options are implemented here.