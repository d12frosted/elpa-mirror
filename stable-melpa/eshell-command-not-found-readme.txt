This package integrates command-not-found in eshell.  It suggests
packages to install when a command is not found.

Requirements:
- command-not-found

Usage:

In `eshell' buffer, if you type a command that is not found, it would suggest
you to install the package that provides the command.

You can customize `eshell-command-not-found-command' to set the path to the
command-not-found executable.  The default value is determined by checking a
few common paths.

To enable this feature, you can either use `eshell-command-not-found-mode' or
customize `eshell-command-not-found-mode' to `t'.
