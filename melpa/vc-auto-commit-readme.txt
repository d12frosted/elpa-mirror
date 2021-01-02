This package allows you to automatically commit all the changes of
a repository. It is useful when you have a project that needs to be
put under a version control system but you don't want to write
any commit message.

; Installation:

Just put the following in your `.emacs`:

(require 'vc-auto-commit)

If you want to auto-commit all repositories when quitting emacs,
add this:

(vc-auto-commit-activate)
