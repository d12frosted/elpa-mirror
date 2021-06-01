This package adjusts the `process-environment' and `exec-path'
variables buffer locally according to the output of a shell script.
The idea is that the same scripts used elsewhere to set up a
project environment can influence external processes started from
buffers editing the project files.  This is important for the
correct operation of tools such as linters, language servers and
the `compile' command, for instance.

The default settings of the package are compatible with the popular
direnv program.  However, this package is entirely independent of
direnv and it's not possible to use direnv-specific features in the
.envrc scripts.  On the plus side, it's possible to configure the
package to support other environment setup methods, such as .env
files or Python virtualenvs.  The package Readme includes some
examples.

The usual way to activate this package is by including the
following in your init file:

    (add-hook 'hack-local-variables-hook 'buffer-env-update)

This way, any buffer potentially affected by directory-local
variables can also be affected by buffer-env.  It is nonetheless
possible to call `buffer-env-update' interactively or add it only
to specific major-mode hooks.

Note that it is quite common for process-executing Emacs libraries
not to heed to the fact that `process-environment' and `exec-path'
may have a buffer-local value.  This unfortunate state of affairs
can be remedied by the `inheritenv' package, which see.
