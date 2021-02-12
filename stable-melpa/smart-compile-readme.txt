This package provides `smart-compile' function.
You can associate a particular file with a particular compile function,
by editing `smart-compile-alist'.
If you are using a build system such as make or cargo, you can associate its build system file with a
compile function as well, by editing `smart-compile-build-system-alist'.

To use this package, add these lines to your .emacs file:
    (require 'smart-compile)

Note that it requires emacs 21 or later.
