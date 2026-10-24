Create releases of Emacs packages and watch them roll down the hill
again.

This package adds three commmands to the `magit-tag' menu.

`sisyphus-bump-package-requires' bumps the versions of dependencies
in the ~Package-Requires~ header of the visited library.

`sisyphus-bump-copyright' bumps the copyright years in libraries,
test files and manuals, and commits the result.

`sisyphus-bump-copyright' reads the new version from the user and
bumps version strings in libraries, test files and manuals.  It
also performs the same tasks as the previous two commands.

This package is opinionated, but it does provide several options, so
it can be tuned to work for people other than me.  However, the focus
was, and continues to be, to make my life easier, so it caters to my
own packaging idiosyncrasies, and I do not intend to invest a lot of
time, making it the right tool for everyone.
