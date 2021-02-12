
Provide Helm commands and sources for Purpose.
Features:
- helmize all Purpose commands
- special helm commands:
  + `helm-purpose-switch-buffer-with-purpose': same as `helm-buffers-list',
    but only list buffers with a specific purpose (default: same purpose as
    current buffer).
  + `helm-purpose-switch-buffer-with-some-purpose': choose a purpose, then
    call `helm-purpose-switch-buffer-with-purpose'.
  + `helm-purpose-mini-ignore-purpose': same as `helm-mini', but
    ignore Purpose when displaying the buffer.

Setup:
Call `helm-purpose-setup' in your init file.  It will helmize all Purpose
commands, but won't change any key bindings.
Alternatively, you can set `purpose-preferred-prompt' to `helm' instead.

Key Bindings:
`helm-purpose' doesn't bind any keys, you are free to define your own
bindings as you please.
