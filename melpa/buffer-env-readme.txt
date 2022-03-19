The purpose of this package is to adjust the `process-environment'
and `exec-path' variables buffer locally according to the output of
a shell script.  This allows the correct operation of tools such as
linters, compilers and language servers when working on projects
with special requirements which are not installed globally on the
system.

The default settings of this package are compatible with the
popular direnv program.  However, the package is entirely
independent of direnv and it's not possible to use direnv-specific
features in the .envrc scripts.  On the plus side, it's possible to
configure the package to support other environment setup methods,
such as .env files or Python virtualenvs.  The README file includes
some examples.

The usual way to activate this package is by including the
following in your init file:

    (add-hook 'hack-local-variables-hook 'buffer-env-update)

In this way, any buffer potentially affected by directory-local
variables will also be affected by buffer-env.  It is nonetheless
possible to call `buffer-env-update' interactively or add it only
to specific major-mode hooks.
