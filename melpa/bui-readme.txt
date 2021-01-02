BUI (Buffer User Interface) is a library for making 'list' (similar
to "M-x list-packages") and 'info' (similar to customization buffers)
interfaces to display various data (packages, buffers, functions,
etc.).

It is not an end-user package, it is a library that is intended to be
used by other packages.

Basically, at first you define 'list'/'info' interface using
`bui-define-interface' macro, and then you can make user commands
that will display entries using `bui-get-display-entries' and similar
functions.

See README at <https://github.com/alezost/bui.el> for more details.
