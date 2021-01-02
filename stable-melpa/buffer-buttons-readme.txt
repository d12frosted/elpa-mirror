
This makes defining, saving, and loading "code-safe" emacs buttons
fairly simple.

You can use `M-x buffer-button-insert` to insert a predefined
button, which can be saved and automatically restored when the file
is loaded.

To define new buttons, use the macro `define-buffer-button`.  See
https://github.com/rpav/buffer-buttons for more information.
