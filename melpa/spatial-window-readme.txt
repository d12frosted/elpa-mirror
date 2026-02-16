Spatial-window provides quick window selection by mapping your keyboard
layout to your window layout.  Each window displays an overlay showing
which keys will select it, based on the spatial correspondence between
keyboard position and window position on screen.

Your eyes look at the target window, your fingers know where that position
is on the keyboard, and you press that key to jump there.

Usage:
  (require 'spatial-window)
  (global-set-key (kbd "M-o") #'spatial-window-select)
