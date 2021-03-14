This package provides a minor-mode to designate buffers as "popups" and
summon and dismiss them with a key. Useful for many things, including
toggling REPLS, documentation, compilation or shell output, etc. This package
will place buffers on your screen, but it works best in conjunction with some
system to handle window creation and placement, like shackle.el. Under the
hood popper summons windows defined by the user as "popups" by simply calling
`display-buffer'.

COMMANDS:

popper-toggle-latest : Toggle latest popup
popper-cycle         : Cycle through all popups, or close all open popups
popper-toggle-type   : Turn a regular window into a popup or vice-versa

CUSTOMIZATION:

`popper-reference-buffers': A list of major modes or regexps whose
corresponding buffer major-modes or regexps (respectively) should be treated
as popups.

`popper-mode-line': String or sexp to show in the mode-line of
popper. Setting this to NIL removes the mode-line entirely from
popper.
