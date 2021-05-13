NOTE: The project API is still experimental and can change in major,
backward-incompatible ways.  Everyone is encouraged to try it, and
report to us any problems or use cases we hadn't anticipated, by
sending an email to emacs-devel, or `M-x report-emacs-bug'.

This file contains generic infrastructure for dealing with
projects, some utility functions, and commands using that
infrastructure.

The goal is to make it easier for Lisp programs to operate on the
current project, without having to know which package handles
detection of that project type, parsing its config files, etc.

This file consists of following parts:

Infrastructure (the public API):

Function `project-current' that returns the current project
instance based on the value of the hook `project-find-functions',
and several generic functions that act on it.

`project-root' must be defined for every project.
`project-files' can be overridden for performance purposes.
`project-ignores' and `project-external-roots' describe the project
files and its relations to external directories.  `project-files'
should be consistent with `project-ignores'.

This list can change in future versions.

VC project:

Originally conceived as an example implementation, now it's a
relatively fast backend that delegates to 'git ls-files' or 'hg
status' to list the project's files.  It honors the VC ignore
files, but supports additions to the list using the user option
`project-vc-ignores' (usually through .dir-locals.el).

Utils:

`project-combine-directories' and `project-subtract-directories',
mainly for use in the abovementioned generics' implementations.

`project-known-project-roots' and `project-remember-project' to
interact with the "known projects" list.

Commands:

`project-prefix-map' contains the full list of commands defined in
this package.  This map uses the prefix `C-x p' by default.
Type `C-x p f' to find file in the current project.
Type `C-x p C-h' to see all available commands and bindings.

All commands defined in this package are implemented using the
public API only.  As a result, they will work with any project
backend that follows the protocol.

Any third-party code that wants to use this package should likewise
target the public API.  Use any of the built-in commands as the
example.

How to create a new backend:

- Consider whether you really should, or whether there are other
ways to reach your goals.  If the backend's performance is
significantly lower than that of the built-in one, and it's first
in the list, it will affect all commands that use it.  Unless you
are going to be using it only yourself or in special circumstances,
you will probably want it to be fast, and it's unlikely to be a
trivial endeavor.  `project-files' is the method to optimize (the
default implementation gets slower the more files the directory
has, and the longer the list of ignores is).

- Choose the format of the value that represents a project for your
backend (we call it project instance).  Don't use any of the
formats from other backends.  The format can be arbitrary, as long
as the datatype is something `cl-defmethod' can dispatch on.  The
value should be stable (when compared with `equal') across
invocations, meaning calls to that function from buffers belonging
to the same project should return equal values.

- Write a new function that will determine the current project
based on the directory and add it to `project-find-functions'
(which see) using `add-hook'.  It is a good idea to depend on the
directory only, and not on the current major mode, for example.
Because the usual expectation is that all files in the directory
belong to the same project (even if some/most of them are ignored).

- Define new methods for some or all generic functions for this
backend using `cl-defmethod'.  A `project-root' method is
mandatory, `project-files' is recommended, the rest are optional.