`now-playing' is an Emacs Transient interface for the macOS Music app.
`now-playing' lets you control the Music app with the following commands:

- Pause/Play (SPC)
- Previous (p) and Next (n) Track
- Open (launch) Music app (o)
- Increase (<up>) and Decrease (<down>) volume
- Refresh current track (r)

`now-playing' is an ancillary interface to the Music app, providing only a
subset of controls to it and no more.

INSTALL

For manual installation, ensure that ‘now-playing.el’ is available in the
Emacs load-path variable.

`now-playing' will take advantage of the macOS SF Symbols font. Use the
convenience command now-playing-init to setup both SF Symbols and to globally
set your keybinding preference (default <f14>) to the Transient menu
`now-playing-tmenu'.

Interactively run “M-x now-playing-init” or add the following line to your
Emacs initialization file:

(now-playing-init "<f14>")

Alternately, a direct setting of your keybinding preference to
`now-playing-tmenu' can be done as follows:

(keymap-global-set "<f14>" #'now-playing-tmenu)

USAGE

Running `now-playing' can be done via “M-x now-playing-tmenu” or by using
your preferred keybinding.
