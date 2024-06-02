posframe is a GNU ELPA package that allow pop a posframe (just a
child-frame) at point.  This file implements a zero-input panel service
using posframe.  This service works in both xorg and wayland sessions.

To use this panel, install posframe package, then add in your
~/.emacs.d/init.el file,

  (require 'zero-input)
  ;; other user configurations
  (when (locate-library "posframe")
    (require 'zero-input-panel-posframe)
    (zero-input-panel-posframe-init))

If the service failed to start, quit the running zero-input panel service
first:

  (zero-input-panel-quit)
