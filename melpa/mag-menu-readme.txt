
Mag-menu provides a menu system intended to be used as an emacs
front-end to command line programs with lots of options (e.g. git or
ack). It presents the options in a visually simple layout in a window
at the bottom of the emacs frame, and makes it easy to toggle
switches or set argument values using just the keyboard.

Mag-menu is derived from the magit-key-mode.el file in magit. The
code was pulled out to make it a standalone elpa package so it could
more easily be used by packages other than magit, and also to make
the code less specific to git. "Mag" in "mag-menu" is short for
magic, but is also meant to suggest its heritage from magit.

The main function is mag-menu.
