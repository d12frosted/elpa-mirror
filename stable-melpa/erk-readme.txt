Set up and develop Emacs packages, complete with Github Actions CI, tests,
lints, documentation generation, and a licensing scheme all ready to go.
Included commands are focused on productivity, appropriate for professional
development in elisp.  The goal of the package is streamline authoring &
distributing new Emacs packages.  It provides a well-integrated but rigid
scheme, aka opinionated.

Simply call `erk-new' to start a new package.  ERK will clone a small
template project and interactively rename and relicense the project.
Instructions on how to host and publish your package are included in the
manual.

As a development aid, the package is versatile enough to work on some elisp
packages not descended from its templates.  The provided functionality
focuses on smoothing out typical workflows.  Common actions like reloading
packages and navigating between source & tests are streamlined.  Processes
like exporting all documents are automated.
