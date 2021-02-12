This package uses "dub describe" to obtain a list of all
dependencies of a D dub project and sets the variable flycheck-dmd-include-paths
so that flycheck syntax checking knows how to call the compiler
and pass it include flags to find the dependencies

If it's not clear what any one function does, consult the unit tests
in the tests directory.

Usage:

     (add-hook 'd-mode-hook 'flycheck-dmd-dub-set-include-path)
