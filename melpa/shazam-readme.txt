shazam.el is an Emacs interface to the Shazam music recognition feature in
macOS 14.2+ (Sonoma or more recent).

INSTALL

This package requires the installation of a macOS Shortcut named "Identify
Music JSON". Download and install it in your library of Shortcuts by clicking
on the link below:

https://www.icloud.com/shortcuts/bba3dd21146c4ba78dff1d7d0c0b1092

shazam.el by default requires your Emacs session to load the macOS SF Symbols
font. Use the convenience command `shazam-init' to setup both SF Symbols and
to globally set your keybinding preference to the `shazam' command.

Add the following line to your Emacs initialization file:

(shazam-init "M-<f19>")

If no binding is desired, `shazam-init' can be called with no arguments.

USAGE

Run the command `shazam' either by your preferred binding or via "M-x".
