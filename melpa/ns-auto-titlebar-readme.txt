Provides a global minor mode, `ns-auto-titlebar-mode' which - when
enabled - keeps the "ns-appearance" frame parameter correctly set
in GUI frames so that it matches the currently-enabled theme,
whether it is light or dark.

For this package to work correctly, it is generally necessary that
the theme you use sets the `frame-background-mode' variable
appropriately.  This can be set manually if necessary, but see the
docs for that variable.

Usage:

    (when (eq system-type 'darwin) (ns-auto-titlebar-mode))

Note that it is safe to omit the "when" condition if you prefer.
