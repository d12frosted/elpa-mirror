Highlight every other `stripes-unit' lines with an alternative
background color.  Useful for buffers that display lists of any
kind, as a guide for your eyes to follow.

The sole entry point of this library is the command `stripes-mode',
which you can invoke manually or from a suitable hook.  Note that
in some cases the choice of the right hook might not be entirely
obvious, e.g. for `dired' you have to use `dired-after-readin-hook'
instead of `dired-mode-hook' unless you're using Emacs >= 28:
https://gitlab.com/stepnem/stripes-el/-/issues/1#note_309176403
