This library defines a global minor mode called `wn-mode' that adds
keyboard shortcuts to quickly switch between visible windows within
the current Emacs frame.

To activate, simply add
  (wn-mode)
to your `~/.emacs'.

By default, the shortcuts are M-1, ..., M-9 for selecting windows
#1 through #9. M-0 selects the minibuffer, if active. M-#
interactively asks which window to select.

With a prefix argument, swaps the buffers between the current and
the target windows.

Customize `wn-keybinding-format' if you wish to use different key
bindings, e.g.:
  (setq wn-keybinding-format "C-c %s")

Re-enable `wn-mode' and the new keybindings will take effect.
