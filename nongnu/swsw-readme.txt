swsw (simple window switching) provides a minor mode for switching
to windows using IDs assigned to them automatically.

Usage:

Enable `swsw-mode':

(swsw-mode)

For use-package users:

(use-package swsw
  :config
  (swsw-mode))

When `swsw-mode' is active:
- A window ID is displayed using a mode line lighter or a display
  function (see `swsw-display-lighter').
- Window IDs are assigned to all windows on all frames except for
  the minibuffer(by default, see `swsw-scope').
- `other-window' (C-x o by default) is remapped to `swsw-select'.

C-x o ID switches focus to the window which corresponds to ID.

C-x o m switches focus to the minibuffer if it's active.

C-x o 0 ID deletes the window which corresponds to ID.

More commands can be added through `swsw-command-map':

(define-key swsw-command-map (kbd "a") #'my-command)

You can customize `swsw-mode' using the customize interface:

M-x customize-group RET swsw RET

For more information see info node `(swsw)'.