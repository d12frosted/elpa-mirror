This package provides a small collection of functions for saving and
loading window and buffer configurations.  A buffer configuration is
a list of buffers and a window configuration is an arrangement of windows
in a frame.  Right now window configurations created only with split
and switch commands are supported.  These functions can be called interactively
(via `M-x`) or from keybindings.

## Functions
### Buffer
 - `windwow-save-buffer-list` - saves current buffers and prompts for name
 - `windwow-load-buffer-list` - loads a previously saved buffer list
 - `windwow-load-buffer-from-list` - loads a buffer from a saved buffer list

### Window
 - `windwow-save-window-configuration` - saves current window configuration
 - `windwow-load-window-configuration` - loads a previously saved window configuration

### Buffer and window
 - `windwow-load-window-configuration-and-buffer-list` - loads a window configuration and a buffer list
