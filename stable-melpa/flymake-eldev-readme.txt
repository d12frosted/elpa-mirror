Add Eldev support to Flymake.

For a project to be detected, it must contain file `Eldev' or
`Eldev-local' in its root directory, even if Eldev doesn’t strictly
require that.

Features:

* No additional steps to be performed from the command line, not
  even `eldev prepare'.

* Project dependencies are seen by Flymake in Emacs.  Similarly, if
  a package is not declared as a dependency of your project,
  Flymake will complain about unimportable features or undeclared
  functions.

* Everything is done on-the-fly.  As you edit your project’s
  dependency list in its main `.el' file, added, removed or
  mistyped dependency names immediately become available to Flymake
  (there might be some delays due to network, as Eldev needs to
  fetch them first).

* Additional test dependencies (see `eldev-add-extra-dependencies')
  are seen from the test files, but not from the main files.

For the extension to have any effect, you need to install Eldev:

    https://github.com/emacs-eldev/eldev#installation
