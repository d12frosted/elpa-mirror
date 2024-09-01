This package has been merged into `magit' itself.

The "git-commit.el" library is no longer distributed as a separate
package.  It is now distributed as part of the `magit' package.

The `git-commit' package now does nothing but display a warning.
If it is located earlier on the `load-path' than `magit' is, then that
prevents the proper "git-commit.el" library from `magit' from being
loaded.

Do not install the `git-commit' package and if it is still installed,
then please uninstalling it and restart Emacs.
