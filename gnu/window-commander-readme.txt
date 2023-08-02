Window Commander provides a minor mode for switching to windows or
performing actions on them using IDs assigned to them automatically.

Usage:

Enable `wincom-mode':

(wincom-mode)

For use-package users:

(use-package window-commander
  :config
  (wincom-mode))

When `wincom-mode' is active:
- A window ID is displayed using a mode line lighter and/or a display
  function (see `wincom-display-lighter').
- Window IDs are assigned to all windows on all frames except for
  the minibuffer (by default, see `wincom-scope').
- `other-window' (C-x o by default) is remapped to `wincom-select'.

C-x o ID	switches focus to the window which corresponds to ID.

C-x o 0 ID	deletes the window which corresponds to ID.

C-x o 1 ID	makes the window which corresponds to ID the sole
		window of its frame.

C-x o 2 ID	splits the window which corresponds to ID from below.

C-x o 3 ID	splits the window which corresponds to ID from the right.

C-x 0 4 ID	displays the buffer of the next command in the window
		which corresponds to ID.

C-x 0 t ID	swaps the states of the current window and the window
		which corresponds to ID.

C-x o m	switches focus to the minibuffer if it's active.

More commands can be added through `wincom-command-map':

(define-key wincom-command-map (kbd "z") #'my-command)

You can customize Window Commander further using the customize interface:

M-x customize-group RET window-commander RET

For more information see info node `(window-commander)'.