
This library bridges perspective mode to the awesome library
Projectile.  The idea is to create a separate perspective when
switching project.  A perspective is an independent workspace for
Emacs, similar to multiple desktops in Gnome and MacOS.  I often
work on many projects at the same time, and using perspective and
projectile together allows me to easily know which project I'm
current in, and focus on files that only belong to current project
when switching buffer.

To use this library, put this file in your Emacs load path, and
call (require 'persp-projectile)

See perspective.el on github: https://github.com/nex3/perspective-el
