This is a basic library to control the Sway window manager from
Emacs.  Its main use case is in combination with popup managers
like Shackle, to 1) use frames instead of windows while still 2)
giving focus to existing frames instead of duplicating them.

This can probably work with i3 by simply reimplementing `sway-msg';
this is left as an exercice to the reader.
