This package provides utilities for interacting with the status bar
program mowedline.

- mowedline-update: performs a mowedline update for the given widget
      and value by dispatching to the function given by
      `mowedline-update-function' (default `mowedline-update/client').

- mowedline-update/client: calls mowedline update via the
      mowedline-client program.

- mowedline-update/dbus: calls mowedline update via dbus directly for
      the given widget and value.

- mowedline-colorize: converts a propertied Emacs string into a string
      of mowedline markup, preserving foreground colors.
