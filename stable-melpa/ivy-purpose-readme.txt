
Provide Ivy commands for Purpose.
Features:
- make Purpose use Ivy interface when `ivy-mode' is on
- special ivy commands:
  + `ivy-purpose-switch-buffer-with-purpose': same as `ivy-switch-buffer',
    but only list buffers with a specific purpose (default: same purpose as
    current buffer).
  + `ivy-purpose-switch-buffer-with-some-purpose': choose a purpose, then
    call `ivy-purpose-switch-buffer-with-purpose'.
  + `ivy-purpose-switch-buffer-without-purpose': same as `ivy-switch-buffer',
    but ignore Purpose when displaying the buffer.

Setup:
Call `ivy-purpose-setup' in your init file.  It will "Ivy-fy" Purpose
commands, but won't change any key bindings.
Alternatively, you can set `purpose-preferred-prompt' to `vanilla' instead.

Key Bindings:
`ivy-purpose' doesn't bind any keys, you are free to define your own
bindings as you please.
