Set up Emacs package with GitHub repository configuration, complete with
Actions CI, tests, lints, documentation generation, and a licensing scheme
all ready to go.  Included commands are focused on productivity, appropriate
for professional development in elisp.  The goal of the package is streamline
authoring & distributing new Emacs packages.  It provides a well-integrated
but rigid scheme, aka opinionated.

The package also uses its own hosted source as a substrate for creating new
packages.  It will clone its source repository and then perform renaming &
re-licensing.  Simply call `erk-new' to start a new package.  The
README documents remaining setup steps on GitHub and in preparation for
publishing on MELPA.

As a development aid, the package is versatile enough to work on some elisp
packages that were not descended from its own source.  The scope of
functionality is primarily to interface with linting and testing frameworks,
both in batch and interactive workflows.
