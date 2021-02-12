
This package provides lightweight support for circular rings of window
configurations.  A window configuration is the layout of windows and
associated buffers within a frame.  There is always at least one
configuration on the ring, the current configuration.  You can create new
configurations and cycle through the layouts in either direction.  You can
also delete configurations from the ring (except the last one of course!).
Window configurations are named, and you can jump to and delete named
configurations.  Display of the current window configuration name in the
mode line supported.

Window configuration rings are frame specific.  That is, each frame has its
own ring which can be cycled through independently of other frames.

You are always looking at the current window configuration for each frame,
which consists of the windows in the frame, the buffers in those windows,
and point in the current buffer.  As you run commands such as "C-x 4 b",
"C-x 2", and "C-x 0" you are modifying the current window configuration.
When you jump to a new configuration, the layout that existed before the
jump is captured, and the ring is rotated to the selected configuration.
Window configurations are captured with `current-window-configuration',
however winring also saves point for the current buffer.

To use, make sure this file is on your `load-path' and put the following in
your .emacs file:

(require 'winring)
(winring-initialize)

Note that by default, this binds the winring keymap to the C-x 7 prefix,
but you can change this by setting the value of `winring-keymap-prefix',
before you call `winring-initialize'.

The following commands are defined:

   C-x 7 n -- Create a new window configuration.  The new
              configuration will contain a single buffer, the one
              named in the variable `winring-new-config-buffer-name'

              With C-u, winring prompts for the name of the new
              configuration.  If you don't use C-u the function in
              `winring-name-generator' will be called to get the
              new configuration's name.

   C-x 7 2 -- Create a duplicate of the current window
              configuration.

   C-x 7 j -- Jump to a named configuration (prompts for the name).

   C-x 7 0 -- Kill the current window configuration and rotate to the
              previous layout on the ring.  You cannot delete the
              last configuration in the ring.  With C-u, prompts
              for the name of the configuration to kill.

   C-x 7 o -- Go to the next configuration on the ring.

   C-x 7 p -- Go to the previous configuration on the ring.

              Note that the sequence `C-x 7 o C-x 7 p' is a no-op;
              it leaves you in the same configuration you were in
              before the sequence.

   C-x 7 r -- Rename the current window configuration.

   C-x 7 b -- Submit a bug report on winring.

   C-x 7 v -- Echo the winring version.
