Popper is a minor-mode to tame the flood of ephemeral windows Emacs
produces, while still keeping them within arm's reach. Designate any
buffer to "popup" status, and it will stay out of your way. Disimss
or summon it easily with one key. Cycle through all your "popups" or
just the ones relevant to your current buffer. Useful for many
things, including toggling display of REPLs, documentation,
compilation or shell output, etc.

For a demo describing usage and customization see
https://www.youtube.com/watch?v=E-xUNlZi3rI

COMMANDS:

popper-mode          : Turn on popup management
popper-toggle-latest : Toggle latest popup
popper-cycle         : Cycle through all popups, or close all open popups
popper-toggle-type   : Turn a regular window into a popup or vice-versa
popper-kill-latest-popup : Kill latest open popup

CUSTOMIZATION:

`popper-reference-buffers': A list of major modes or regexps whose
corresponding buffer major-modes or regexps (respectively) should be
treated as popups.

`popper-mode-line': String or sexp to show in the mode-line of
popper. Setting this to nil removes the mode-line entirely from
popper.

`popper-group-function': Function that returns the context a popup
should be shown in. The context is a string or symbol used to group
together a set of buffers and their associated popups, such as the
project root. Customize for available options.

`popper-display-control': This package summons windows defined by the
user as popups by simply calling `display-buffer'. By default,
it will display your popups in a non-obtrusive way. If you want
Popper to display popups according to window rules you specify in
`display-buffer-alist' (or through a package like Shackle), set this
variable to nil.

There are other customization options, such as the ability to suppress
certain popups and keep them from showing. Please customize the popper group
for details.
