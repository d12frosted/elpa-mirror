
This package allows you to interact with a
plaster paste service directly from within
Emacs.

By default this package uses the service at
  https://plaster.tymoon.eu
However, you can also configure your own setup
if you so desire. The Plaster server app can
be obtained at
  https://github.com/Shirakumo/plaster

The following commands are available:

- plaster-login
    If you have a plaster account, use this
    to log yourself in.
- plaster-visit
    Opens an existing paste in a buffer
- plaster-paste-buffer
    Pastes the current buffer to a new paste
- plaster-paste-region
    Pastes the current region to a new paste
- plaster-new
    Opens a new buffer for a new paste
- plaster-annotate                    (C-x C-a)
    Create an annotation for the current paste
- plaster-save                        (C-x C-s)
    Save the current buffer as a paste
- plaster-delete                      (C-x C-k)
    Delete the current buffer's paste

The keybindings mentioned are only active in
plaster-mode buffers.
