Popwin makes you free from the hell of annoying buffers such like
*Help*, *Completions*, *compilation*, and etc.

To use popwin, just add the following code into your .emacs:

    (require 'popwin)
    (popwin-mode 1)

Then try to show some buffer, for example *Help* or
*Completeions*.  Unlike standard behavior, their buffers may be
shown in a popup window at the bottom of the frame.  And you can
close the popup window seamlessly by typing C-g or selecting other
windows.

`popwin:display-buffer' displays special buffers in a popup window
and displays normal buffers as unsual.  Special buffers are
specified in `popwin:special-display-config', which tells popwin
how to display such buffers.  See docstring of
`popwin:special-display-config' for more information.

The default width/height/position of popup window can be changed by
setting `popwin:popup-window-width', `popwin:popup-window-height',
and `popwin:popup-window-position'.  You can also change the
behavior for a specific buffer.  See docstring of
`popwin:special-display-config'.

If you want to use some useful commands such like
`popwin:popup-buffer' and `popwin:find-file' easily.  You may bind
`popwin:keymap' to `C-z', for example, like:

    (global-set-key (kbd "C-z") popwin:keymap)

See also `popwin:keymap' documentation.

Enjoy!
