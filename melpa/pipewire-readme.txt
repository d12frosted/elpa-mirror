
PipeWire user interface and library.
It currently uses pw-cli and pw-metadata command line utilities to
interact with PipeWire.

An interactive PipeWire buffer can be displayed using `M-x pipewire'.
There you can view basic PipeWire status and change some settings.
`pipewire-increase-volume', `pipewire-decrease-volume' and
`pipewire-toggle-muted' functions can be used also standalone and
are suitable to bind on the multimedia keys.

The package can be used also non-interactively in Elisp programs.
See pipewire-lib.el source file for available functions.
