The Borg assimilate Emacs packages as Git submodules.

Borg is a bare-bones package manager for Emacs packages.  It provides
only a few essential features, and should be combined with other tools
such as `magit', `epkg', and `auto-compile'.

Borg assimilates packages into the "~/.config/emacs" (or "~/.emacs.d")
repository as Git submodules.  An assimilated package is called a
drone.  It is possible to clone a package, without immediately also
assimilating it, allowing you to review it, before performing that
second step.

Borg can be used by itself or alongside `package.el'.
