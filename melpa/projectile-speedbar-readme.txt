
This package sits on top of speedbar and projectile and provides an
easy to use and useful integration between the two.

With this package when you switch between projects that work with
projectile, speedbar will automatically show the directly listing
of that project as well as expand the tree to show the file in the
project.

Features that are required by this library:

 `speedbar' `sr-speedbar' `projectile'

To invoke this function manually:

`projectile-speedbar-open-current-buffer-in-tree


; Installation

Copy speedbar-projectile.el to your load-path and add this to ~/.emacs

 (require 'projectile-speedbar)
