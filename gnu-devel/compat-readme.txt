Compat is the Elisp forwards compatibility library, which provides
definitions introduced in newer Emacs versions.  The definitions
are only installed if necessary for your current Emacs version.  If
Compat is compiled on a recent version of Emacs, all of the
definitions are disabled at compile time, such that no negative
performance impact is incurred.  The provided compatibility
implementations of functions and macros are at least subsets of the
actual implementations.  Be sure to read the documentation string
and the Compat manual.

Not every function provided in newer versions of Emacs is provided
here.  Some depend on new features from the C core, others cannot
be implemented to a meaningful degree.  Please consult the Compat
manual for details regarding the usage of the Compat library and
the provided functionality.

The main audience for this library are not regular users, but
package maintainers.  Therefore no commands, user-facing modes or
user options are implemented here.