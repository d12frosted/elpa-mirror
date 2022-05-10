Extension of `project' to detect project root with root file (e.g. Gemfile).

It is useful when editing files outside of VCS.  And it may also be useful if
you are using monorepo.  It is very smiller to Projectile's
'projectile-root-top-down', but it relies on the Emacs standard `project'.

Usage:

As is the default for Projectile, you prefer a VCS root over a root file
for project detection, add the following to your init file:

     (add-to-list 'project-find-functions #'project-rootfile-try-detect t)

Otherwise, if you prefer a root file, add the following:

     (add-to-list 'project-find-functions #'project-rootfile-try-detect)

For more information, please see <https://github.com/buzztaiki/project-rootfile.el>.
