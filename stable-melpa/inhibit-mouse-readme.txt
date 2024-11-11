The inhibit-mouse package allows the disabling of mouse input in Emacs using
inhibit-mouse-mode.

Instead of modifying the keymap of its own mode (as the disable-mouse package
does), enabling inhibit-mouse-mode only modifies input-decode-map to disable
mouse events, making it more efficient and faster than disable-mouse.

Additionally, the inhibit-mouse package allows for the restoration of mouse
input when inhibit-mouse-mode is disabled.
