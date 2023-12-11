
Keep all Emacs configuration in a separate directory that can be
under version control with very short init.el change.  Using
init-dir is as simple as putting the following single line in the
actual init.el file:

(load-init-dir)

This also comes with a very lightweight init profiler to warn you
if your Emacs startup is slow.
