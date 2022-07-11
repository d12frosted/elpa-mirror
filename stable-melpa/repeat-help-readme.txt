repeat-help shows key descriptions when using Emacs' `repeat-mode'.

The description can be in the form a Which Key popup or an Embark indicator
(which see). To use it, enable `repeat-mode' (Emacs 28.0.5 and up) and
`repeat-help-mode'. When using a repeated key binding, you can press `C-h' to
toggle a popup with the available keybindings.

To change the key to toggle the popup type, customize `repeat-help-key'.

To have the popup show automatically, set `repeat-help-auto' to true.

By default the package tries to use an Embark key indicator. To use Which-Key
or the built-in hints, customize `repeat-help-popup-type'.
