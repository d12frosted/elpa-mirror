This package provides a minor-mode to designate buffers as "popups" and
summon and dismiss them with a key. Useful for many things, including
toggling REPLS, documentation, compilation or shell output, etc. This package
will place buffers on your screen, but it works best in conjunction with some
system to handle window creation and placement, like shackle.el. Under the
hood popper summons windows defined by the user as "popups" by simply calling
`display-buffer'.

For a demo describing usage and customization see
https://www.youtube.com/watch?v=E-xUNlZi3rI

COMMANDS:

popper-toggle-latest : Toggle latest popup
popper-cycle         : Cycle through all popups, or close all open popups
popper-toggle-type   : Turn a regular window into a popup or vice-versa
popper-kill-latest-popup : Kill latest open popup

CUSTOMIZATION:

`popper-reference-buffers': A list of major modes or regexps whose
corresponding buffer major-modes or regexps (respectively) should be treated
as popups.

`popper-mode-line': String or sexp to show in the mode-line of
popper. Setting this to nil removes the mode-line entirely from
popper.

`popper-group-function': Function that returns the context a popup should be
shown in. The context is a string or symbol used to group together a set of
buffers and their associated popups, such as the project root. See
documentation for available options.
