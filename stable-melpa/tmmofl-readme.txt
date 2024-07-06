
This code is used to run to functions depending on whether the
current font-lock font is at point.  As font-lock is usually
syntactically meaningful this means that you can for instance
toggle minor modes on and off depending on the current syntax.

To install this software place this file and the tmmofl-x.el file
into your load path and place

(require 'tmmofl)

if your .emacs.

To switch on this minor mode use the command tmmofl-mode.  The mode
line will indicate that the mode is switched on.  What this actually
does will depend on what the main mode of the current buffer
is.  The default behaviour is to switch `auto-fill' mode on when
point is within comments, and off when its in anything else.
