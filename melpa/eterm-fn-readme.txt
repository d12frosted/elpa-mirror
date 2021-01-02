This library provides the ‘eterm-fn-mode’: a global minor mode that
makes term mode capable of handling the keyboard function keys
(F1--F12).  This consists of detecting their presses and sending
their respective escape codes to the underlying process and also
providing a terminfo database to export such capabilities to
ncurses-based applications.  The X11R6 xterm’s escape codes are
used.

Both standard 16 colors and extended 256 colors terminals are
supported.  The latter is provided by package ‘eterm-256color’,
which is automatically detected in case it’s present.

Customize the variable ‘eterm-fn-mode’ to enable this mode globally.
