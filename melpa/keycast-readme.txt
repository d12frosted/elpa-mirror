This package provides four modes that display the current command and
its key or mouse binding.

- `keycast-mode-line-mode' shows the current binding at the bottom of
  the selected window, in its mode line.

- `keycast-header-line-mode' shows the current binding at the top of
  the selected window, in its header line.

- `keycast-tab-bar-mode' shows the current binding at the top of
  the selected frame, in its tab bar.

- `keycast-log-mode' displays a list of recent bindings in a dedicated
  frame.

A fifth mode, `keycast-invisible-mode', determines the current binding,
but without displaying it anywhere.  Use `keycast-format' to format the
current binding, and write your own code to display it somewhere.
