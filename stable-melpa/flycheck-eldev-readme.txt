Add Eldev support to Flycheck.

For a project to be detected, it must contain file `Eldev' or
`Eldev-local' in its root directory, even if Eldev doesn’t strictly
require that.

Features:

* No additional steps to be performed from the command line, not
  even `eldev prepare'.  However, you might need to mark the
  project as trusted, use M-x customize-group flycheck-eldev RET.

* Project dependencies are seen by Flycheck in Emacs.  Similarly,
  if a package is not declared as a dependency of your project,
  Flycheck will complain about unimportable features or undeclared
  functions.

* Everything is done on-the-fly.  As you edit your project’s
  dependency list in its main `.el' file, added, removed or
  mistyped dependency names immediately become available to
  Flycheck (there might be some delays due to network, as Eldev
  needs to fetch them first).

* Additional test dependencies (see `eldev-add-extra-dependencies')
  are seen from the test files, but not from the main files.

For the extension to have any effect, you need to install Eldev:

    https://github.com/doublep/eldev#installation

If Flycheck doesn’t seem to recognize dependencies declared in a
project, verify its setup (`C-c !  v').
