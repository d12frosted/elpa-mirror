This package adds a cmake backend for Emacs' project.el framework.

The added value comes from cmake's reliance on external build directories
which breaks `project-compile` when using the default project.el backend.
This also adds some convenience functions for configuring projects and
running unit tests.

For more information see the README.org on the github page of the project.
