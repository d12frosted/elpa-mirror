
The main function, `ace-window' is meant to replace `other-window'
by assigning each window a short, unique label.  When there are only
two windows present, `other-window' is called (unless
aw-dispatch-always is set non-nil).  If there are more, each
window will have its first label character highlighted.  Once a
unique label is typed, ace-window will switch to that window.

To setup this package, just add to your .emacs:

   (global-set-key (kbd "M-o") 'ace-window)

replacing "M-o"  with an appropriate shortcut.

By default, ace-window uses numbers for window labels so the window
labeling is intuitively ordered.  But if you prefer to type keys on
your home row for quicker access, use this setting:

   (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))

Whenever ace-window prompts for a window selection, it grays out
all the window characters, highlighting window labels in red.  To
disable this behavior, set this:

   (setq aw-background nil)

If you want to know the selection characters ahead of time, turn on
`ace-window-display-mode'.

When prefixed with one `universal-argument', instead of switching
to the selected window, the selected window is swapped with the
current one.

When prefixed with two `universal-argument', the selected window is
deleted instead.
